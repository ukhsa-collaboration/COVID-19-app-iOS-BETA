//
//  StatusStateMigration.swift
//  Sonar
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum SelfDiagnosisType: String, Codable {
    case initial
    case subsequent
}

// This class continues to exist to allow migrating old data but is otherwise unused
struct SelfDiagnosis: Codable, Equatable {
    let type: SelfDiagnosisType
    let symptoms: Set<Symptom>
    let startDate: Date
    var expiryDate: Date = Date()
}

class StatusStateMigration {

    private let dateProvider: () -> Date

    private var currentDate: Date { dateProvider() }

    init(dateProvider: @escaping () -> Date = { Date() }) {
        self.dateProvider = dateProvider
    }

    func migrate(
        diagnosis: SelfDiagnosis?,
        potentiallyExposedOn: Date?
    ) -> StatusState {
        switch (diagnosis, potentiallyExposedOn) {
        case (.none, .none):
            return .ok(StatusState.Ok())
        case (.none, .some(let date)):
            // This should never happen, but date types, right?
            guard let delta = daysSince(date) else {
                return .ok(StatusState.Ok())
            }

            // If it's been 14 days, you're ok again
            guard delta < 14 else {
                return .ok(StatusState.Ok())
            }

            return .exposed(StatusState.Exposed(exposureDate: date))
        case (.some(let diagnosis), _):
            guard !diagnosis.symptoms.isEmpty else {
                return .ok(StatusState.Ok())
            }

            if currentDate > diagnosis.expiryDate || diagnosis.type == .subsequent {
                return .checkin(
                    StatusState.Checkin(
                        symptoms: diagnosis.symptoms,
                        checkinDate: diagnosis.expiryDate
                    )
                )
            } else {
                return .symptomatic(
                    StatusState.Symptomatic(
                        symptoms: diagnosis.symptoms,
                        startDate: diagnosis.startDate
                    )
                )
            }
        }
    }

    private func daysSince(_ date: Date) -> Int? {
        let dateComponents = Calendar.current.dateComponents(
            [.day],
            from: date,
            to: currentDate
        )
        return dateComponents.day
    }

}
