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
    func received(_ testResult: TestResult)
}

class StatusStateMachine: StatusStateMachining {
    static let StatusStateChangedNotification = NSNotification.Name("StatusStateChangedNotification")

    private let logger = Logger(label: "StatusStateMachine")
    private let checkinNotificationIdentifier = "Diagnosis"
    private let exposedNotificationIdentifier = "exposedNotificationIdentifier"
    private let adviceChangedNotificationIdentifier = "adviceChangedNotificationIdentifier"

    private let persisting: Persisting
    private let contactEventsUploader: ContactEventsUploading
    private let drawerMailbox: DrawerMailboxing
    private let notificationCenter: NotificationCenter
    private let userNotificationCenter: UserNotificationCenter
    private let dateProvider: () -> Date

    private(set) var state: StatusState {
        get { persisting.statusState }
        set {
            guard persisting.statusState != newValue else { return }

            persisting.statusState = newValue
            userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [checkinNotificationIdentifier])

            switch newValue {
            case .symptomatic(let symptomatic):
                add(notificationRequest: checkinNotificationRequest(at: symptomatic.checkinDate))
            case .exposed:
                add(notificationRequest: adviceChangedNotificationRequest)
            default:
                break
            }

            notificationCenter.post(
                name: StatusStateMachine.StatusStateChangedNotification,
                object: self
            )
        }
    }

    private var currentDate: Date { dateProvider() }

    private var nextCheckinDate: Date? {
        let startOfDay = Calendar.current.startOfDay(for: currentDate)
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
        drawerMailbox: DrawerMailboxing,
        notificationCenter: NotificationCenter,
        userNotificationCenter: UserNotificationCenter,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader
        self.drawerMailbox = drawerMailbox
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
        case .ok, .exposed:
            try contactEventsUploader.upload(from: startDate, with: symptoms)

            let firstCheckin = StatusState.Symptomatic.firstCheckin(from: startDate)
            let pastFirstCheckin = currentDate >= firstCheckin
            let hasTemperature = symptoms.contains(.temperature)

            guard !pastFirstCheckin || pastFirstCheckin && hasTemperature else {
                // Don't change states if we're past the initial
                // checkin date but don't have a temperature
                drawerMailbox.post(.symptomsButNotSymptomatic)
                return
            }

            let checkinDate = pastFirstCheckin ? StatusState.Symptomatic.nextCheckin(from: currentDate) : firstCheckin
            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate, checkinDate: checkinDate)
            state = .symptomatic(symptomatic)
        case .symptomatic, .positiveTestResult:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }
    
    func tick() {
        switch state {
        case .ok, .symptomatic:
            break // Don't need to do anything
        case .exposed(let exposed):
            guard currentDate >= exposed.expiryDate else { return }

            state = .ok(StatusState.Ok())
        case .positiveTestResult(let positive):
            guard currentDate >= positive.expiryDate else { return }

            let symptomatic = StatusState.Symptomatic(
                symptoms: positive.symptoms,
                startDate: positive.startDate,
                checkinDate: positive.expiryDate
            )
            state = .symptomatic(symptomatic)
        }
    }

    func checkin(symptoms: Symptoms) {
        switch state {
        case .ok, .exposed, .positiveTestResult:
            assertionFailure("Checking in is only allowed from symptomatic")
            return
        case .symptomatic(let symptomatic):
            guard currentDate >= symptomatic.checkinDate else {
                assertionFailure("Checking in is only allowed after the checkin date")
                return
            }

            if symptoms.contains(.temperature) {
                let checkinDate = StatusState.Symptomatic.nextCheckin(from: currentDate)
                let nextCheckin = StatusState.Symptomatic(symptoms: symptoms, startDate: symptomatic.startDate, checkinDate: checkinDate)
                state = .symptomatic(nextCheckin)
            } else {
                if !symptoms.isEmpty {
                    drawerMailbox.post(.symptomsButNotSymptomatic)
                }
                state = .ok(StatusState.Ok())
            }
        }
    }

    func exposed() {
        switch state {
        case .ok:
            let exposed = StatusState.Exposed(startDate: currentDate)
            state = .exposed(exposed)
        case .exposed:
            assertionFailure("The server should never send us another exposure notification if we're already exposed")
            break // ignore repeated exposures
        case .symptomatic, .positiveTestResult:
            break // don't care about exposures if we're already symptomatic
        }
    }

    func unexposed() {
        switch state {
        case .exposed:
            add(notificationRequest: adviceChangedNotificationRequest)
            drawerMailbox.post(.unexposed)
            state = .ok(StatusState.Ok())
        case .ok, .symptomatic, .positiveTestResult:
            break // no-op
        }
    }

    func received(_ testResult: TestResult) {
        add(notificationRequest: testResultNotification)

        switch testResult.result {
        case .positive:
            handlePositiveTestResult(from: testResult.testTimestamp)
        case .unclear:
            drawerMailbox.post(.unclearTestResult)
        case .negative:
            handleNegativeTestResult(from: testResult.testTimestamp)
        }
    }
    
    func handlePositiveTestResult(from testDate: Date) {
        switch state {
        case .ok, .exposed:
            let positive = StatusState.PositiveTestResult(symptoms: nil, startDate: testDate)
            state = .positiveTestResult(positive)
        case .symptomatic(let symptomatic):
            let startDate = min(symptomatic.startDate, testDate)
            let positive = StatusState.PositiveTestResult(symptoms: symptomatic.symptoms, startDate: startDate)
            state = .positiveTestResult(positive)
        case .positiveTestResult:
            let message = "Received positive test result, in a state where it is not expected"
            assertionFailure(message)
            self.logger.error("\(message)")
        }

        drawerMailbox.post(.positiveTestResult)
    }

    func handleNegativeTestResult(from testDate: Date) {
        var symptoms: Symptoms?

        switch state {
        case .ok, .exposed:
            break
        case .symptomatic(let symptomatic):
            if testDate > symptomatic.startDate {
                symptoms = symptomatic.symptoms
            }
        case .positiveTestResult(let positive):
            if testDate > positive.startDate {
                state = .ok(StatusState.Ok())
            }
        }

        drawerMailbox.post(.negativeTestResult(symptoms: symptoms))
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
