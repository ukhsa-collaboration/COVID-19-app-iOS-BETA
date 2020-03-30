//
//  RegistrationViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController, Storyboarded {
    static let storyboardName = "Registration"
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var registerButton: UIButton!

    var registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared

    var registrationService: RegistrationService!
    var notificationManager: NotificationManager!
    var delegate: RegistrationSavedDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        registerButton.setTitle("Register", for: .normal)

        if #available(iOS 13, *) {
            activityIndicator.style = .medium
        }
    }

    @IBAction func didTapRegister(_ sender: Any) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        registerButton.isEnabled = false

        registrationService.register { [weak self] result in
            guard let self = self else { return }

            self.activityIndicator.stopAnimating()

            switch result {
            case .success(let registration):
                self.delegate.registrationDidFinish(with: registration)
            case .failure(let error):
                print("Unable to register, got error: \(error)")
                self.registerButton.isEnabled = false
            }
        }
    }

}

