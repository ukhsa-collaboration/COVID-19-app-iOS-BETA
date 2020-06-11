//
//  RegistrationTryable.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationAttemptable: Attemptable {
    var delegate: AttemptableDelegate?
    var state: AttemptableState = .initial
    var numAttempts = 0
    var numSuccesses = 0
    var deadline: Date?

    let timeoutSecs = 5 * 60.0
    
    private var registrationService: ConcreteRegistrationService!
    private var persistence: RegistrationPersisting!
    
    init(registrationService: ConcreteRegistrationService, persistence: RegistrationPersisting) {
        self.registrationService = registrationService
        self.persistence = persistence
        
        registrationService.timeoutSecs = timeoutSecs
        registrationService.delayBeforeAllowingRetrySecs = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(succeed), name: RegistrationCompletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fail), name: RegistrationFailedNotification, object: nil)
    }
    
    func attempt() {
        state = .inProgress
        deadline = Date().advanced(by: timeoutSecs)
        self.delegate?.attemptableDidChange(self)
        registrationService.register()
    }
    
    @objc private func succeed() {
        numAttempts += 1
        numSuccesses += 1
        persistence.registration = nil // allow retry
        state = .succeeded
        deadline = nil
        delegate?.attemptableDidChange(self)
    }
    
    @objc private func fail() {
        numAttempts += 1
        state = .failed
        deadline = nil
        delegate?.attemptableDidChange(self)
    }
}
