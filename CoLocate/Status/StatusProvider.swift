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
        case (.some, _):
            return .amber
        default:
            return .blue
        }
    }

    let persisting: Persisting


    init(persisting: Persisting) {
        self.persisting = persisting
    }

}
