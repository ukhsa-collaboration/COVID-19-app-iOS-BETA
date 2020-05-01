//
//  StatusProviderDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class StatusProviderDouble: StatusProvider {
    static func double() -> StatusProviderDouble {
        return StatusProviderDouble(persisting: PersistenceDouble())
    }

    var _status: Status = .blue
    override var status: Status {
        get { _status }
        set { _status = newValue }
    }
    
    override var amberExpiryDate: Date? {
        switch _status {
        case .amber:
            return Date(timeIntervalSince1970: 0)
        default:
            return nil
        }
    }
}
