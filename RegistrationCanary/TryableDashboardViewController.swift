//
//  ViewController.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/9/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AttemptableDashboardViewController: UIViewController, AttemptableDelegate {
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var statsLabel: UILabel!
    
    private var attemptable: Attemptable!
        
    func inject(attemptable: Attemptable) {
        self.attemptable = attemptable
        self.attemptable.delgate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    @IBAction func attempt() {
        attemptable.attempt()
    }
    
    func attemptableDidChange(_ sender: Attemptable) {
        update()
    }

    
    private func update() {
        let prefix = "Current/last attempt:"
        
        switch attemptable.state {
        case .initial:
            statusLabel.text = "\(prefix) not started"
            button.isEnabled = true
        case .inProgress:
            statusLabel.text = "\(prefix) in progress"
            button.isEnabled = false
        case .failed:
            statusLabel.text = "\(prefix) failed"
            button.isEnabled = true
        case .succeeded:
            statusLabel.text = "\(prefix) succeeded"
            button.isEnabled = true
        }
        
        let pct = attemptable.numAttempts == 0
            ? "0.0"
            : String(format: "%.1f", 100 * (Double(attemptable.numSuccesses) / Double(attemptable.numAttempts)))
        statsLabel.text = "\(attemptable.numSuccesses)/\(attemptable.numAttempts) attempts succeeded (\(pct)%)"
    }
}
