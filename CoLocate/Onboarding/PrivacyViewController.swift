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

    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func dataSharingAllowedChanged(_ sender: UISwitch) {
        persistence.allowedDataSharing = sender.isOn
        continueButton.isEnabled = sender.isOn
    }
}
