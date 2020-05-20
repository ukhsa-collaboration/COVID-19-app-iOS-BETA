//
//  StatusStateMachine.swift
//  Sonar
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

protocol StatusStateMachining {
    var state: StatusState { get }

    func selfDiagnose(symptoms: Symptoms, startDate: Date) throws
    func tick()
    func checkin(symptoms: Symptoms)
    func exposed()
}

class StatusStateMachine: StatusStateMachining {

    static let StatusStateChangedNotification = NSNotification.Name("StatusStateChangedNotification")

    private let logger = Logger(label: "StatusStateMachine")
    private let checkinNotificationIdentifier = "Diagnosis"

    private let persisting: Persisting
    private var contactEventsUploader: ContactEventsUploading
    private let notificationCenter: NotificationCenter
    private let userNotificationCenter: UserNotificationCenter
    private let dateProvider: () -> Date

    private(set) var state: StatusState {
        get { persisting.statusState }
        set {
            persisting.statusState = newValue

            notificationCenter.post(
                name: StatusStateMachine.StatusStateChangedNotification,
                object: self
            )
        }
    }

    private var nextCheckinDate: Date? {
        let startOfDay = Calendar.current.startOfDay(for: dateProvider())
        guard let afterDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        return Calendar.current.nextDate(
            after: afterDay,
            matching: DateComponents(hour: 7),
            matchingPolicy: .nextTime
        )
    }

    init(
        persisting: Persisting,
        contactEventsUploader: ContactEventsUploading,
        notificationCenter: NotificationCenter,
        userNotificationCenter: UserNotificationCenter,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader
        self.notificationCenter = notificationCenter
        self.userNotificationCenter = userNotificationCenter
        self.dateProvider = dateProvider
    }

    func selfDiagnose(symptoms: Symptoms, startDate: Date) throws {
        guard symptoms.hasCoronavirusSymptoms else {
            assertionFailure("Self-diagnosing with no symptoms is not allowed")
            return
        }

        switch state {
        case .ok(let ok):
            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate)
            try contactEventsUploader.upload(from: startDate, with: symptoms)

            if dateProvider() < symptomatic.expiryDate {
                transition(from: ok, to: symptomatic)
            } else { // expired
                if symptoms.contains(.temperature) {
                    transition(from: ok, to: symptomatic)

                    // go straight into checkin
                    guard let checkinDate = nextCheckinDate else { return }
                    let checkin = StatusState.Checkin(symptoms: symptomatic.symptoms, checkinDate: checkinDate)
                    transition(from: symptomatic, to: checkin)
                } else {
                    // don't do anything if we only have a cough
                }
            }
        case .exposed(let exposed):
            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate)
            try contactEventsUploader.upload(from: startDate, with: symptoms)
            transition(from: exposed, to: symptomatic)
        case .symptomatic, .checkin:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }

    func tick() {
        switch state {
        case .ok, .checkin:
            break // Don't need to do anything
        case .symptomatic(let symptomatic):
            guard dateProvider() >= symptomatic.expiryDate else { return }

            let checkin = StatusState.Checkin(symptoms: symptomatic.symptoms, checkinDate: symptomatic.expiryDate)
            transition(from: symptomatic, to: checkin)
        case .exposed(let exposed):
            guard dateProvider() >= exposed.expiryDate else { return }

            transition(from: exposed, to: StatusState.Ok())
        }
    }

    func checkin(symptoms: Symptoms) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [checkinNotificationIdentifier])

        switch state {
        case .ok, .symptomatic, .exposed:
            assertionFailure("Checking in is only allowed from checkin")
            return
        case .checkin(let checkin):
            guard dateProvider() >= checkin.checkinDate else {
                assertionFailure("Checking in is only allowed after the checkin date")
                return
            }

            if symptoms.contains(.temperature) {
                guard let checkinDate = nextCheckinDate else { return }

                transition(
                    from: checkin,
                    to: StatusState.Checkin(symptoms: symptoms, checkinDate: checkinDate)
                )
            } else {
                transition(from: checkin, to: StatusState.Ok())
            }
        }
    }

    func exposed() {
        switch state {
        case .ok(let ok):
            transition(from: ok, to: StatusState.Exposed(exposureDate: dateProvider()))
        case .exposed:
            assertionFailure("The server should never send us another exposure notification if we're already exposed")
            break // ignore repeated exposures
        case .symptomatic, .checkin:
            break // don't care about exposures if we're already symptomatic
        }
    }

    // MARK: - Transitions

    private func transition(from ok: StatusState.Ok, to symptomatic: StatusState.Symptomatic) {
        add(notificationRequest: checkinNotificationRequest(at: symptomatic.expiryDate))
        state = .symptomatic(symptomatic)
    }

    private func transition(from symptomatic: StatusState.Symptomatic, to checkin: StatusState.Checkin) {
        add(notificationRequest: checkinNotificationRequest(at: checkin.checkinDate))
        state = .checkin(checkin)
    }

    private func transition(from exposed: StatusState.Exposed, to symptomatic: StatusState.Symptomatic) {
        add(notificationRequest: checkinNotificationRequest(at: symptomatic.expiryDate))
        state = .symptomatic(symptomatic)
    }

    private func transition(from exposed: StatusState.Exposed, to ok: StatusState.Ok) {
        state = .ok(ok)
    }

    private func transition(from previous: StatusState.Checkin, to next: StatusState.Checkin) {
        add(notificationRequest: checkinNotificationRequest(at: next.checkinDate))
        state = .checkin(next)
    }

    private func transition(from checkin: StatusState.Checkin, to ok: StatusState.Ok) {
        state = .ok(ok)
    }

    private func transition(from ok: StatusState.Ok, to exposed: StatusState.Exposed) {
        add(notificationRequest: exposedNotificationRequest)
        state = .exposed(exposed)
    }

    // MARK: - User Notifications

    private func add(notificationRequest: UNNotificationRequest) {
        userNotificationCenter.add(notificationRequest) { error in
            guard error != nil else {
                self.logger.critical("Unable to add local notification: \(String(describing: error))")
                return
            }
        }
    }

    private func checkinNotificationRequest(at date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "NHS COVID-19"
        content.body = "How are you feeling today?\n\nPlease open the app to update your symptoms and view your latest advice. Your help saves lives."

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: checkinNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        return request
    }

    private lazy var exposedNotificationRequest: UNNotificationRequest = {
        let content = UNMutableNotificationContent()
        content.title = "POTENTIAL_STATUS_TITLE".localized
        content.body = "POTENTIAL_STATUS_BODY".localized

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        return request
    }()

}
