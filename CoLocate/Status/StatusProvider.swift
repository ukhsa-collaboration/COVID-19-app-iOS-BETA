//
//  StatusProvider.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Status: Equatable {
    case blue, amber, red
}

class StatusProvider {

    var status: Status {
        switch (persisting.potentiallyExposed, persisting.selfDiagnosis?.isAffected) {
        case (_, .some(true)):
            return .red
        case (.some(let date), _):
            guard let delta = daysSince(date), delta < 14 else { return .blue }
            return .amber
        default:
            return .blue
        }
    }

    private var currentDate: Date { currentDateProvider() }

    let persisting: Persisting
    let currentDateProvider: () -> Date

    init(
        persisting: Persisting,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.persisting = persisting
        self.currentDateProvider = currentDateProvider
    }

    func daysSince(_ date: Date) -> Int? {
        let dateComponents = Calendar.current.dateComponents(
            [.day],
            from: date,
            to: currentDate
        )
        return dateComponents.day
    }

}
