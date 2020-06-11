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
    @IBOutlet var secondaryStatusLabel: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var statsLabel: UILabel!
    
    private var attemptable: Attemptable!
    private var timer: Timer!
        
    func inject(attemptable: Attemptable) {
        self.attemptable = attemptable
        self.attemptable.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSecondaryStatus), userInfo: nil, repeats: true)
        update()
    }

    @IBAction func attempt() {
        attemptable.attempt()
    }
    
    func attemptableDidChange(_ sender: Attemptable) {
        update()
    }
    
    var enableManualAttempt: Bool = true {
        didSet {
            button.isHidden = !enableManualAttempt
        }
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
        case .errored(_):
            statusLabel.text = "\(prefix) errored"
            button.isEnabled = true
        case .succeeded:
            statusLabel.text = "\(prefix) succeeded"
            button.isEnabled = true
        }
        
        let pct = attemptable.numAttempts == 0
            ? "0.0"
            : String(format: "%.1f", 100 * (Double(attemptable.numSuccesses) / Double(attemptable.numAttempts)))
        statsLabel.text = "\(attemptable.numSuccesses)/\(attemptable.numAttempts) attempts succeeded (\(pct)%)"
        updateSecondaryStatus()
    }
    
    @objc private func updateSecondaryStatus() {
        switch attemptable.state {
        case .inProgress(let deadline):
            secondaryStatusLabel.isHidden = false
            let secs = Int(Date().distance(to: deadline))
            secondaryStatusLabel.text = "Timeout in: \(secs) seconds"
            secondaryStatusLabel.textColor = .label
        case .errored(let message):
            secondaryStatusLabel.isHidden = false
            secondaryStatusLabel.text = message
            secondaryStatusLabel.textColor = .red
        default:
            secondaryStatusLabel.isHidden = true
        }
    }
}
