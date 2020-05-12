//
//  StatusStateMachine.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class StatusStateMachine {

    private let persisting: Persisting
    private let dateProvider: () -> Date

    private(set) var state: StatusState {
        get { persisting.statusState }
        set { persisting.statusState = newValue }
    }

    init(
        persisting: Persisting,
        dateProvider: @autoclosure @escaping () -> Date = Date()
    ) {
        self.persisting = persisting
        self.dateProvider = dateProvider
    }

    func selfDiagnose(symptoms: Set<Symptom>, startDate: Date) {
        guard !symptoms.isEmpty else {
            assertionFailure("Self-diagnosing with no symptoms is not allowed")
            return
        }

        switch state {
        case .ok, .exposed:
            let startOfStartDate = Calendar.current.startOfDay(for: startDate)
            let expiryDate = Calendar.current.nextDate(
                after: Calendar.current.date(byAdding: .day, value: 7, to: startOfStartDate)!,
                matching: DateComponents(hour: 7),
                matchingPolicy: .nextTime
            )!
            state = .symptomatic(symptoms: symptoms, expires: expiryDate)
        case .symptomatic, .checkin:
            assertionFailure("Self-diagnosing is only allowed from ok/exposed")
        }
    }

    func tick() {
        switch state {
        case .ok, .checkin:
            break // Don't need to do anything
        case .symptomatic(let symptoms, let expiry):
            guard dateProvider() >= expiry else { return }
            state = .checkin(symptoms: symptoms, at: expiry)
        case .exposed(let exposureDate):
            let fourteenDaysLater = Calendar.current.nextDate(
                after: Calendar.current.date(byAdding: .day, value: 13, to: exposureDate)!,
                matching: DateComponents(hour: 7),
                matchingPolicy: .nextTime
            )!

            guard dateProvider() >= fourteenDaysLater else { return }

            state = .ok
        }
    }

    func checkin(symptoms: Set<Symptom>) {
        switch state {
        case .ok, .symptomatic, .exposed:
            assertionFailure("Checking in is only allowed from checkin")
        case .checkin(_, let date):
            guard dateProvider() >= date else {
                assertionFailure("Checking in is only allowed after the checkin date")
                return
            }

            if symptoms.contains(.temperature) {
                let startOfDay = Calendar.current.startOfDay(for: dateProvider())
                let nextCheckin = Calendar.current.nextDate(
                    after: Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!,
                    matching: DateComponents(hour: 7),
                    matchingPolicy: .nextTime
                )!
                state = .checkin(symptoms: symptoms, at: nextCheckin)
            } else {
                state = .ok
            }
        }
    }

    func exposed() {
        switch state {
        case .ok:
            let date = dateProvider()
            state = .exposed(on: date)
        case .exposed:
            break // ignore repeated exposures
        case .symptomatic, .checkin:
            break // don't care about exposures if we're already symptomatic
        }
    }

}
