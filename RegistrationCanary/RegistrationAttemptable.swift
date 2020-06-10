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

    let timeoutSecs = 5 * 60.0
    
    private var registrationService: ConcreteRegistrationService!
    private var persistence: RegistrationPersisting!
    
    init(registrationService: ConcreteRegistrationService, persistence: RegistrationPersisting) {
        self.registrationService = registrationService
        self.persistence = persistence
        
        registrationService.timeoutSecs = timeoutSecs
        registrationService.delayBeforeAllowingRetrySecs = 0
        
        NotificationCenter.default.addObserver(forName: RegistrationCompletedNotification, object: nil, queue: nil) { _ in
            self.numAttempts += 1
            self.numSuccesses += 1
            self.persistence.registration = nil // allow retry
            self.state = .succeeded
            self.delegate?.attemptableDidChange(self)
        }
        
        NotificationCenter.default.addObserver(forName: RegistrationFailedNotification, object: nil, queue: nil) { _ in
            self.numAttempts += 1
            self.state = .failed
            self.delegate?.attemptableDidChange(self)
        }
    }
    
    func attempt() {
        state = .inProgress
        self.delegate?.attemptableDidChange(self)
        registrationService.register()
    }
    

}
