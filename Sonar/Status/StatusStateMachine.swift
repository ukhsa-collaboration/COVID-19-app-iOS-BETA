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
        case .ok(let ok):
            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate)
            transition(from: ok, to: symptomatic)
        case .exposed(let exposed):
            let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: startDate)
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
            state = .checkin(StatusState.Checkin(symptoms: symptomatic.symptoms, checkinDate: symptomatic.expiryDate))
        case .exposed(let exposed):
            let fourteenDaysLater = Calendar.current.nextDate(
                after: Calendar.current.date(byAdding: .day, value: 13, to: exposed.exposureDate)!,
                matching: DateComponents(hour: 7),
                matchingPolicy: .nextTime
            )!

            guard dateProvider() >= fourteenDaysLater else { return }

            transition(from: exposed, to: StatusState.Ok())
        }
    }

    func checkin(symptoms: Set<Symptom>) {
        switch state {
        case .ok, .symptomatic, .exposed:
            assertionFailure("Checking in is only allowed from checkin")
        case .checkin(let checkin):
            guard dateProvider() >= checkin.checkinDate else {
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
                transition(
                    from: checkin,
                    to: StatusState.Checkin(symptoms: symptoms, checkinDate: nextCheckin)
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
        state = .symptomatic(symptomatic)
    }

    private func transition(from exposed: StatusState.Exposed, to symptomatic: StatusState.Symptomatic) {
        state = .symptomatic(symptomatic)
    }

    private func transition(from exposed: StatusState.Exposed, to ok: StatusState.Ok) {
        state = .ok(ok)
    }

    private func transition(from previous: StatusState.Checkin, to next: StatusState.Checkin) {
        state = .checkin(next)
    }

    private func transition(from checkin: StatusState.Checkin, to ok: StatusState.Ok) {
        state = .ok(ok)
    }

    private func transition(from ok: StatusState.Ok, to exposed: StatusState.Exposed) {
        state = .exposed(exposed)
    }

}
