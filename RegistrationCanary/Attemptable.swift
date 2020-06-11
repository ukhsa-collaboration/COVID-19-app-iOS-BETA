//
//  Tryable.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum AttemptableState {
    case initial
    case inProgress(deadline: Date)
    case succeeded
    case failed
    // "errored" represents failures that indicate a problem with the canary
    // rather than a problem with the system under test.
    case errored(message: String)
}


protocol Attemptable {
    var delegate: AttemptableDelegate? { get set }
    var state: AttemptableState { get }
    var numAttempts: Int { get }
    var numSuccesses: Int { get }
    
    func attempt()
}

protocol AttemptableDelegate {
    func attemptableDidChange(_ sender: Attemptable)
}
