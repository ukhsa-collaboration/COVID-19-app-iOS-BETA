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
    func set(state: StatusState)
    func received(_ testResult: TestResult)
    
    func clearInterstitialState()
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
            guard persisting.statusState != newValue else { return }

            persisting.statusState = newValue

            switch newValue {
            case .symptomatic(let symptomatic):
                add(notificationRequest: checkinNotificationRequest(at: symptomatic.checkinDate))
            case .exposed, .unexposed:
                add(notificationRequest: adviceChangedNotificationRequest)
            case .positiveTestResult, .negativeTestResult, .unclearTestResult:
                add(notificationRequest: testResultNotification)
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
    
    func clearInterstitialState() {
        state = state.resolved()
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

            let checkinDate: Date
            switch (pastFirstCheckin, hasTemperature) {
            case (false, _):
                checkinDate = firstCheckin
            case (true, true):
                checkinDate = StatusState.Symptomatic.nextCheckin(from: currentDate)
            case (true, false):
                // Don't change states if we're past the initial checkin
                // date but don't have a temperature
                return
            }

            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate, checkinDate: checkinDate)
            state = .symptomatic(symptomatic)
        case .symptomatic, .unexposed, .positiveTestResult, .unclearTestResult, .negativeTestResult:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }
    
    func tick() {
        switch state {
        case .ok, .symptomatic, .unexposed, .negativeTestResult:
            break // Don't need to do anything
        case .unclearTestResult(let unclear):
            guard currentDate >= unclear.expiryDate else { return }

            let symptomatic = StatusState.Symptomatic(
                symptoms: unclear.symptoms,
                startDate: unclear.startDate,
                checkinDate: unclear.expiryDate
            )
            state = .symptomatic(symptomatic)
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
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [checkinNotificationIdentifier])

        switch state {
        case .ok, .exposed, .unexposed, .positiveTestResult, .unclearTestResult, .negativeTestResult:
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
                state = .ok(StatusState.Ok())
            }
        }
    }

    func exposed() {
        switch state.resolved() {
        case .ok:
            let exposed = StatusState.Exposed(startDate: currentDate)
            state = .exposed(exposed)
        case .unexposed:
            state = .exposed(StatusState.Exposed(startDate: currentDate))
        case .exposed:
            assertionFailure("The server should never send us another exposure notification if we're already exposed")
            break // ignore repeated exposures
        case .symptomatic, .positiveTestResult, .unclearTestResult:
            break // don't care about exposures if we're already symptomatic
        case .negativeTestResult:
            assertionFailure("Status state's resolve method should not return an interstitial state")
            break
        }
    }

    func unexposed() {
        switch state.resolved() {
        case .exposed:
            state = .unexposed(StatusState.Unexposed())
        case .ok, .symptomatic, .unexposed, .positiveTestResult, .unclearTestResult:
            break // no-op
        case .negativeTestResult:
            assertionFailure("Status state's resolve method should not return an interstitial state")
            break
        }
    }

    func ok() {
        guard case .unexposed = state else {
            assertionFailure("This transition is only for going to ok from unexposed")
            return
        }

        state = .ok(StatusState.Ok())
    }

    func received(_ testResult: TestResult) {
        switch testResult.result {
        case .positive:
            receivedPositiveTestResult()
        case .unclear:
            receivedUnclearTestResult()
        case .negative:
            receivedNegativeTestResult(testTimestamp: testResult.testTimestamp)
        }
    }
    
    func receivedPositiveTestResult() {
        switch state {
        case .ok, .exposed, .negativeTestResult:
            let positive = StatusState.PositiveTestResult(symptoms: nil, startDate: currentDate)
            state = .positiveTestResult(positive)
        case .symptomatic(let symptomatic):
            let positive = StatusState.PositiveTestResult(symptoms: symptomatic.symptoms, startDate: symptomatic.startDate)
            state = .positiveTestResult(positive)
        case .unclearTestResult(let unclearTestResult):
            let positive = StatusState.PositiveTestResult(symptoms: unclearTestResult.symptoms, startDate: unclearTestResult.startDate)
            state = .positiveTestResult(positive)
        case .unexposed, .positiveTestResult:
            let message = "Received positive test result, in a state where it is not expected"
            assertionFailure(message)
            self.logger.error("\(message)")
        }
    }
    
    func receivedNegativeTestResult(testTimestamp: Date) {
        switch state.resolved() {
        case .symptomatic(let symptomatic) where symptomatic.startDate < testTimestamp:
            state = .negativeTestResult(
                nextState: .ok(StatusState.Ok())
            )
        default:
            state = .negativeTestResult(
                nextState: state
            )
        }
    }
    
    func set(state: StatusState) {
        self.state = state
    }
    
    func receivedUnclearTestResult() {
        state = .unclearTestResult(StatusState.UnclearTestResult(symptoms: state.symptoms, startDate: currentDate))
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
