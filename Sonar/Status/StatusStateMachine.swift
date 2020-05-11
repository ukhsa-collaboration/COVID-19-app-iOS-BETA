//
//  StatusStateMachine.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum StatusState: Equatable {
    case ok // default state, previously "blue"
    case symptomatic(hasTemperature: Bool, hasCough: Bool, startDate: Date) // previously "red" state
    case checkin(hasTemperature: Bool, hasCough: Bool, checkinDate: Date)
    case exposed(on: Date) // previously "amber" state
}

class StatusStateMachine {

    init() {
    }

}
