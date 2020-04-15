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

    @IBAction func continueTapped() {
        guard allowDataSharingSwitch.isOn else {
            showAlert()
            return
        }
        
        persistence.allowedDataSharing = true
        self.continueHandler()
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: nil, message: "To continue, please agree to share your app data with the NHS.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
