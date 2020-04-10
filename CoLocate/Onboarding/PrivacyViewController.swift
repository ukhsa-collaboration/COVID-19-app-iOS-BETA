//
//  PrivacyViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PrivacyViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var persistence: Persisting! = nil
    private var continueHandler: (() -> Void)! = nil
    
    func inject(persistence: Persisting, continueHandler: @escaping () -> Void) {
        self.persistence = persistence
        self.continueHandler = continueHandler
    }
    
    @IBOutlet weak var allowDataSharingSwitch: UISwitch!
    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func allowDataSharingChanged(_ sender: UISwitch) {
        continueButton.isEnabled = sender.isOn
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        persistence.allowedDataSharing = true
        self.continueHandler()
    }
}
