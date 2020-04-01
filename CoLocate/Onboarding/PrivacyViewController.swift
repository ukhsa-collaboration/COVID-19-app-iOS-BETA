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

    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func dataSharingAllowedChanged(_ sender: UISwitch) {
        persistance.allowedDataSharing = sender.isOn
        continueButton.isEnabled = sender.isOn
    }
}
