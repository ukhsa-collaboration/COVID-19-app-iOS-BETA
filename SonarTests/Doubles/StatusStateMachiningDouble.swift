//
//  StatusStateMachiningDouble.swift
//  SonarTests
//
//  Created by NHSX on 5/12/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class StatusStateMachiningDouble: StatusStateMachining {
    var state: StatusState

    init(state: StatusState = .ok(StatusState.Ok())) {
        self.state = state
    }

    var exposedCalled = false
    func exposed() {
        exposedCalled = true
    }

    var selfDiagnosisCalled: (symptoms: Symptoms, startDate: Date)?
    func selfDiagnose(symptoms: Symptoms, startDate: Date) throws {
        selfDiagnosisCalled = (symptoms: symptoms, startDate: startDate)
    }

    var tickCalled = false
    func tick() {
        tickCalled = true
    }

    var checkinSymptoms: Symptoms?
    func checkin(symptoms: Symptoms) {
        checkinSymptoms = symptoms
    }

    func unexposed() {
    }

}
