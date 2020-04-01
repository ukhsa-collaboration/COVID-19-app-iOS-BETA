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

    let persistence = Persistence.shared

    @IBOutlet weak var allowDataSharingSwitch: UISwitch!
    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func allowDataSharingChanged(_ sender: UISwitch) {
        continueButton.isEnabled = sender.isOn
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        persistence.allowedDataSharing = allowDataSharingSwitch.isOn
        performSegue(withIdentifier: "unwindFromPrivacy", sender: self)
    }
}
