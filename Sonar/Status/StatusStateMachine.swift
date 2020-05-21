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
    func unexposed()
    func ok()
    func received(_ result: TestResult.Result)
}

class StatusStateMachine: StatusStateMachining {
    static let StatusStateChangedNotification = NSNotification.Name("StatusStateChangedNotification")

    private let logger = Logger(label: "StatusStateMachine")
    private let checkinNotificationIdentifier = "Diagnosis"
    private let exposedNotificationIdentifier = "exposedNotificationIdentifier"
    private let adviceChangedNotificationIdentifier = "adviceChangedNotificationIdentifier"

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
        case .symptomatic, .checkin, .unexposed, .positiveTestResult:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }

    func tick() {
        switch state {
        case .ok, .checkin, .unexposed:
            break // Don't need to do anything
        case .symptomatic(let symptomatic):
            guard dateProvider() >= symptomatic.expiryDate else { return }

            let checkin = StatusState.Checkin(symptoms: symptomatic.symptoms, checkinDate: symptomatic.expiryDate)
            transition(from: symptomatic, to: checkin)
        case .exposed(let exposed):
            guard dateProvider() >= exposed.expiryDate else { return }

            transition(from: exposed, to: StatusState.Ok())
        case .positiveTestResult(let positiveTestResult):
            guard dateProvider() >= positiveTestResult.expiryDate else { return }
            
            let checkin = StatusState.Checkin(symptoms: positiveTestResult.symptoms, checkinDate: positiveTestResult.expiryDate)
            transition(from: positiveTestResult, to: checkin)
        }
    }

    func checkin(symptoms: Symptoms) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [checkinNotificationIdentifier])

        switch state {
        case .ok, .symptomatic, .exposed, .unexposed, .positiveTestResult:
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
            transition(from: ok, to: StatusState.Exposed(startDate: dateProvider()))
        case .unexposed(let unexposed):
            transition(from: unexposed, to: StatusState.Exposed(startDate: dateProvider()))
        case .exposed:
            assertionFailure("The server should never send us another exposure notification if we're already exposed")
            break // ignore repeated exposures
        case .symptomatic, .checkin, .positiveTestResult:
            break // don't care about exposures if we're already symptomatic
        }
    }

    func unexposed() {
        switch state {
        case .exposed(let exposed):
            transition(from: exposed, to: StatusState.Unexposed())
        case .ok, .symptomatic, .checkin, .unexposed, .positiveTestResult:
            break // no-op
        }
    }

    func ok() {
        guard case .unexposed(let unexposed) = state else {
            assertionFailure("This transition is only for going to ok from unexposed")
            return
        }

        transition(from: unexposed, to: StatusState.Ok())
    }

    func received(_ result: TestResult.Result) {
        add(notificationRequest: testResultNotification)

        guard result == .positive else {
            let message = "\(result): Not handled yet"
            assertionFailure(message)
            self.logger.error("\(message)")
            return
        }

        switch state {
        case .symptomatic(let symptomatic):
            transition(to: StatusState.PositiveTestResult(symptoms: symptomatic.symptoms, startDate: symptomatic.startDate))
        case .ok, .checkin, .exposed, .unexposed, .positiveTestResult:
            let message = "\(result) from \(state): Not handled yet"
            assertionFailure(message)
            self.logger.error("\(message)")
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
        add(notificationRequest: adviceChangedNotificationRequest)
        state = .exposed(exposed)
    }
    
    private func transition(from positiveTestResult: StatusState.PositiveTestResult, to checkin: StatusState.Checkin) {
        state = .checkin(checkin)
    }
    
    private func transition(to positiveTestResult: StatusState.PositiveTestResult) {
        add(notificationRequest: testResultNotification)
        state = .positiveTestResult(positiveTestResult)
    }

    private func transition(from unexposed: StatusState.Unexposed, to exposed: StatusState.Exposed) {
        add(notificationRequest: adviceChangedNotificationRequest)
        state = .exposed(exposed)
    }

    private func transition(from exposed: StatusState.Exposed, to unexposed: StatusState.Unexposed) {
        add(notificationRequest: adviceChangedNotificationRequest)
        state = .unexposed(unexposed)
    }

    private func transition(from unexposed: StatusState.Unexposed, to ok: StatusState.Ok) {
        state = .ok(ok)
    }

    // MARK: - User Notifications

    private func add(notificationRequest: UNNotificationRequest) {
        userNotificationCenter.add(notificationRequest) { error in
            if let error = error {
                self.logger.critical("Unable to add local notification: \(String(describing: error))")
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

    private lazy var adviceChangedNotificationRequest: UNNotificationRequest = {
        let content = UNMutableNotificationContent()
        content.title = "ADVICE_CHANGED_NOTIFICATION_TITLE".localized
        content.body = "ADVICE_CHANGED_NOTIFICATION_BODY".localized

        return UNNotificationRequest(identifier: adviceChangedNotificationIdentifier, content: content, trigger: nil)
    }()
    
    private lazy var testResultNotification: UNNotificationRequest = {
        let content = UNMutableNotificationContent()
        content.title = "TEST_RESULT_TITLE".localized
        content.body = "TEST_RESULT_BODY".localized

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        return request
    }()

}
