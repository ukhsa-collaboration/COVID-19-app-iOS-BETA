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

    let persistance = Persistance.shared

    @IBOutlet weak var allowDataSharingSwitch: UISwitch!
    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func dataSharingAllowedChanged(_ sender: UISwitch) {
        continueButton.isEnabled = sender.isOn
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        persistance.allowedDataSharing = allowDataSharingSwitch.isOn
        performSegue(withIdentifier: "unwindFromPrivacy", sender: self)
    }
}
