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
    @IBOutlet var retryButton: UIButton!

    var coordinator: AppCoordinator?
    var registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared

    var registrationService: RegistrationService!
    var notificationManager: NotificationManager!

    var registerWhenTokenReceived = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        retryButton.setTitle("Register", for: .normal)
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        registrationService.register { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(_):
                self.coordinator?.launchEnterDiagnosis()
            case .failure(_):
                self.enableRetry()
            }
        }
    }
        
    private func enableRetry() {
        self.retryButton.isHidden = false
        self.activityIndicator.stopAnimating()
    }
}

