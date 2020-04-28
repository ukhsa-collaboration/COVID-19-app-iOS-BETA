//
//  StatusProviderDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import CoLocate

class StatusProviderDouble: StatusProvider {
    static func double() -> StatusProviderDouble {
        return StatusProviderDouble(persisting: PersistenceDouble())
    }

    var _status: Status = .blue
    override var status: Status {
        get { _status }
        set { _status = newValue }
    }
}
