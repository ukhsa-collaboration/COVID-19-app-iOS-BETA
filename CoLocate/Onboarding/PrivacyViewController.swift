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

    var interactor: PrivacyViewControllerInteracting = PrivacyViewControllerInteractor()
    
    @IBOutlet weak var allowDataSharingSwitch: UISwitch!
    @IBOutlet weak var continueButton: PrimaryButton!

    @IBAction func allowDataSharingChanged(_ sender: UISwitch) {
        continueButton.isEnabled = sender.isOn
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        interactor.allowDataSharing {
            self.performSegue(withIdentifier: "unwindFromPrivacy", sender: self)
        }
    }
}

protocol PrivacyViewControllerInteracting {
    func allowDataSharing(completion: @escaping () -> Void)
}

class PrivacyViewControllerInteractor: PrivacyViewControllerInteracting {
    
    private let persistence: Persisting
    
    init(persistence: Persisting = Persistence.shared) {
        self.persistence = persistence
    }
    
    func allowDataSharing(completion: @escaping () -> Void) {
        persistence.allowedDataSharing = true
        completion()
    }
    
}
