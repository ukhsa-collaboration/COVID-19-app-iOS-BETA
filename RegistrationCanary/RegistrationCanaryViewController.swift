//
//  RegistrationCanaryViewController.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

// TODO: figure out if this is the ideal value.
// We want to test frequently, but not so frequently that APNS throttles us.
private let automaticRetrySecs = 30 * 60.0

class RegistrationCanaryViewController: UIViewController, Storyboarded {
    static let storyboardName = "Main"
    
    @IBOutlet var automaticSwitch: UISwitch!
    @IBOutlet var autoRetryLabel: UILabel!
    private var registration: RegistrationAttemptable!
    private var apns: ApnsAttemptable!
    private var lastTimerId = 0
    private var lastCanceledTimerId = 0
    private var dashboards: [AttemptableDashboardViewController] = []
    private var backgroundableTimer = BackgroundableTimer(notificationCenter: NotificationCenter.default, queue: DispatchQueue.main)
    private var recurringUpdateTimer: Timer!

    func inject(
        registrationService: ConcreteRegistrationService,
        persistence: RegistrationPersisting
    ) {
        registration = RegistrationAttemptable(registrationService: registrationService, persistence: persistence)
        apns = ApnsAttemptable()
    }
    
    override func viewDidLoad() {
        autoRetryEnabled = false
        recurringUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAutoRetryLabel), userInfo: nil, repeats: true)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! AttemptableDashboardViewController
        dashboards.append(dest)
        
        if segue.identifier == "EmbedRegistration" {
            dest.inject(attemptable: registration)
        } else if segue.identifier == "EmbedAPNs" {
            dest.inject(attemptable: apns)
        } else {
            fatalError("Unrecognized segue identifier: \(String(describing: segue.identifier))")
        }
    }
    
    @IBAction func automaticSwitchChanged(_ sender: UISwitch) {
        autoRetryEnabled = sender.isOn
        
        if sender.isOn {
            startAutomatic()
        } else {
            stopAutomatic()
        }
    }
    
    private var autoRetryEnabled: Bool = false {
        didSet {
            automaticSwitch.isOn = autoRetryEnabled
            
            if !autoRetryEnabled {
                nextAutomaticRetry = nil
            }
            
            for vc in dashboards {
                vc.enableManualAttempt = !autoRetryEnabled
            }
        }
    }
    
    private var nextAutomaticRetry: Date? = nil {
        didSet {
            updateAutoRetryLabel()
        }
    }
    
    @objc private func updateAutoRetryLabel() {
        autoRetryLabel.isHidden = nextAutomaticRetry == nil

        if let nextDate = nextAutomaticRetry {
            let delta = Date().distance(to: nextDate)
            let sDelta: String
            
            if delta >= 60 {
                let minutes = (delta / 60).rounded()
                sDelta = "\(Int(minutes)) minutes"
            } else {
                sDelta = "\(Int(delta)) seconds"
            }
            
            autoRetryLabel.text = "Next auto retry in: \(sDelta)"
        }
    }
    
    private func startAutomatic() {
        logger.info("Retrying automatically")
        let timerId = lastTimerId + 1
        lastTimerId += 1
        
        registration.attempt()
        apns.attempt()
        
        nextAutomaticRetry = Date().addingTimeInterval(automaticRetrySecs)
        backgroundableTimer.schedule(deadline: .now() + automaticRetrySecs) {
            self.nextAutomaticRetry = nil
            
            if self.lastCanceledTimerId < timerId {
                self.startAutomatic()
            }
        }
    }
    
    private func stopAutomatic() {
        // Let anything in flight finish, but don't kick off new auto attempts
        lastCanceledTimerId = lastTimerId
    }
}

private let logger = Logging.Logger(label: "RegistrationCanaryViewController")
