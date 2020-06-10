//
//  ViewController.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/9/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

enum State {
    case initial
    case registering
    case succeeded
    case failed
}

class ViewController: UIViewController, Storyboarded {
    static let storyboardName = "Main"

    @IBOutlet var registrationStatusLabel: UILabel!
    @IBOutlet var registerButton: UIButton!
        
    private var state: State = .initial
    private var registrationService: RegistrationService!
    private var persistence: RegistrationPersisting!
    
    func inject(registrationService: RegistrationService, persistence: RegistrationPersisting) {
        self.registrationService = registrationService
        self.persistence = persistence
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: RegistrationCompletedNotification, object: nil, queue: nil) { _ in
            self.persistence.registration = nil // allow retry
            self.state = .succeeded
            self.update()
        }
        
        NotificationCenter.default.addObserver(forName: RegistrationFailedNotification, object: nil, queue: nil) { _ in
            self.state = .failed
            self.update()
        }
        
        update()
    }

    @IBAction func register() {
        state = .registering
        update()
        registrationService.register()
    }
    
    private func update() {
        let prefix = "Current/last registration:"
        
        switch state {
        case .initial:
            registrationStatusLabel.text = "\(prefix) not started"
            registerButton.isEnabled = true
        case .registering:
            registrationStatusLabel.text = "\(prefix) in progress"
            registerButton.isEnabled = false
        case .failed:
            registrationStatusLabel.text = "\(prefix) failed"
            registerButton.isEnabled = true
        case .succeeded:
            registrationStatusLabel.text = "\(prefix) succeeded"
            registerButton.isEnabled = true
        }
    }
}
