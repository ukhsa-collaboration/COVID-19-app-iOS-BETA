//
//  RegistrationCanaryViewController.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationCanaryViewController: UIViewController, Storyboarded {
    static let storyboardName = "Main"
    
    private var registration: RegistrationAttemptable!
    private var apns: ApnsAttemptable!
    
    func inject(
        registrationService: ConcreteRegistrationService,
        persistence: RegistrationPersisting
    ) {
        registration = RegistrationAttemptable(registrationService: registrationService, persistence: persistence)
        apns = ApnsAttemptable()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! AttemptableDashboardViewController
        
        if segue.identifier == "EmbedRegistration" {
            dest.inject(attemptable: registration)
        } else if segue.identifier == "EmbedAPNs" {
            dest.inject(attemptable: apns)
        } else {
            fatalError("Unrecognized segue identifier: \(String(describing: segue.identifier))")
        }
    }
}
