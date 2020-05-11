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
    case symptomatic(symptoms: Set<Symptom>, expires: Date) // previously "red" state
    case checkin(symptoms: Set<Symptom>, at: Date)
    case exposed(on: Date) // previously "amber" state
}

class StatusStateMachine {

    init() {
    }

}
