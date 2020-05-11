//
//  StatusStateMachine+Migration.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension StatusStateMachine {

    static func migrate(diagnosis: SelfDiagnosis?, potentiallyExposedOn: Date?) -> StatusState {
        return .ok
    }

}
