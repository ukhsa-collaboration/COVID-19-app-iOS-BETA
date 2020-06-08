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
    func exposed(on date: Date)
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
            case .exposedSymptomatic(let exposedSymptomatic):
                add(notificationRequest: checkinNotificationRequest(at: exposedSymptomatic.checkinDate))
            case .exposed(let exposed):
                add(notificationRequest: adviceChangedNotificationRequest())
                add(notificationRequest: adviceChangedNotificationRequest(at: exposed.expiryDate))
            case .ok, .positiveTestResult:
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
        case .exposed(let exposed):
            try contactEventsUploader.upload(from: startDate, with: symptoms)
            
            let firstCheckin = max(StatusState.ExposedSymptomatic.firstCheckin(from: startDate), exposed.expiryDate)
            
            let pastFirstCheckin = currentDate >= firstCheckin
            let hasTemperature = symptoms.contains(.temperature)

            guard !pastFirstCheckin || pastFirstCheckin && hasTemperature else {
                // Don't change states if we're past the initial
                // checkin date but don't have a temperature
                return
            }

            let exposedSymptomatic = StatusState.ExposedSymptomatic(
                exposed: exposed,
                symptoms: symptoms,
                startDate: startDate,
                checkinDate: firstCheckin
            )
            state = .exposedSymptomatic(exposedSymptomatic)
            
        case .ok:
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
            
        case .symptomatic, .positiveTestResult, .exposedSymptomatic:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }
    
    func tick() {
        switch state {
        case .ok, .symptomatic, .exposedSymptomatic, .positiveTestResult:
            break // Don't need to do anything
        case .exposed(let exposed):
            guard currentDate >= exposed.expiryDate else { return }
            drawerMailbox.post(.unexposed)
            state = .ok(StatusState.Ok())
        }
    }

    func checkin(symptoms: Symptoms) {
        switch state {
        case .ok, .exposed:
            assertionFailure("Checking in is only allowed from symptomatic")
            return
        case .exposedSymptomatic(let state):
            checkin(state: state, symptoms: symptoms)
        case .symptomatic(let state):
            checkin(state: state, symptoms: symptoms)
        case .positiveTestResult(let state):
            checkin(state: state, symptoms: symptoms)
        }
    }
    
    func checkin<T>(state: T, symptoms: Symptoms) where T: Checkinable & SymptomProvider {
        if symptoms.contains(.temperature) {
            let checkinDate = T.nextCheckin(from: currentDate)
            if state is StatusState.PositiveTestResult {
                let nextCheckin = StatusState.PositiveTestResult(checkinDate: checkinDate, symptoms: symptoms, startDate: state.startDate)
                self.state = .positiveTestResult(nextCheckin)
            } else {
                let nextCheckin = StatusState.Symptomatic(symptoms: symptoms, startDate: state.startDate, checkinDate: checkinDate)
                self.state = .symptomatic(nextCheckin)
            }
        } else {
            if !symptoms.isEmpty {
                drawerMailbox.post(.symptomsButNotSymptomatic)
            }
            self.state = .ok(StatusState.Ok())
        }
    }

    func exposed(on date: Date) {
        switch state {
        case .ok:
            let exposed = StatusState.Exposed(startDate: date)
            state = .exposed(exposed)
        case .exposed, .exposedSymptomatic:
            #warning("Should the duration of the exposed state be reset? (14 days)")
            assertionFailure("The server should never send us another exposure notification if we're already exposed")
            break // ignore repeated exposures
        case .symptomatic, .positiveTestResult:
            break // don't care about exposures if we're already symptomatic
        }
    }

    func unexposed() {
        switch state {
        case .exposed:
            add(notificationRequest: adviceChangedNotificationRequest())
            drawerMailbox.post(.unexposed)
            state = .ok(StatusState.Ok())
        case .ok, .symptomatic, .positiveTestResult, .exposedSymptomatic:
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
        let startDate: Date = {
            switch state {
            case .ok, .exposed:
                return testDate
            case .symptomatic, .positiveTestResult, .exposedSymptomatic:
                return min(testDate, state.startDate ?? testDate)
            }
        }()
        
        let checkinDate = StatusState.PositiveTestResult.firstCheckin(from: startDate)
        let positive = StatusState.PositiveTestResult(checkinDate: checkinDate, symptoms: state.symptoms, startDate: testDate)
        state = .positiveTestResult(positive)
        drawerMailbox.post(.positiveTestResult)
    }

    func handleNegativeTestResult(from testDate: Date) {
        switch state {
        case .ok, .exposed, .positiveTestResult:
            break
        case .exposedSymptomatic(let exposedSymptomatic):
            let exposed = exposedSymptomatic.exposed
            if exposed.expiryDate > currentDate {
                state = .exposed(exposed)
            } else {
                state = .ok(StatusState.Ok())
            }
        case .symptomatic(let symptomatic):
            if testDate > symptomatic.startDate {
                state = .ok(StatusState.Ok())
            }
        }

        drawerMailbox.post(.negativeTestResult)
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

        let request = UNNotificationRequest(
            identifier: checkinNotificationIdentifier,
            content: content,
            trigger: makeNotificationTrigger(date)
        )

        return request
    }

    private func adviceChangedNotificationRequest(at date: Date? = nil) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "ADVICE_CHANGED_NOTIFICATION_TITLE".localized
        content.body = "ADVICE_CHANGED_NOTIFICATION_BODY".localized

        let request = UNNotificationRequest(
            identifier: adviceChangedNotificationIdentifier,
            content: content,
            trigger: makeNotificationTrigger(date)
        )

        return request
    }
    
    private lazy var testResultNotification: UNNotificationRequest = {
        let content = UNMutableNotificationContent()
        content.title = "TEST_RESULT_TITLE".localized
        content.body = "TEST_RESULT_BODY".localized

        let request = UNNotificationRequest(identifier: "testResult.arrived", content: content, trigger: nil)
        return request
    }()

    private func makeNotificationTrigger(_ date: Date?) -> UNNotificationTrigger? {
        guard let date = date else { return nil }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
