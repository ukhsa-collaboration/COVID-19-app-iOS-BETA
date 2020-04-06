//
//  RegistrationViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class RegistrationViewController: UIViewController, Storyboarded {
    static let storyboardName = "Registration"
    
    @IBOutlet var registerButton: PrimaryButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var registrationService: RegistrationService = ConcreteRegistrationService()
    var mainQueue: AsyncAfterable = DispatchQueue.main
    private var attempt: Cancelable?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""

        if #available(iOS 13, *) {
            activityIndicator.style = .medium
        }
    }

    @IBAction func didTapRegister(_ sender: UIButton) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        registerButton.isEnabled = false

        attempt = registrationService.register { [weak self] result in
            guard let self = self else { return }
            
            self.attempt = nil

            if case .failure(let error) = result {
                logger.error("Unable to register: \(error)")
                self.showFailureAlert()
                self.enableRetry()
            }
        }
        
        mainQueue.asyncAfter(deadline: .now() + maxRegistrationSecs) { [weak self] in
            guard let self = self, let attempt = self.attempt else { return }

            logger.error("Registration attempt timed out after \(maxRegistrationSecs) seconds")
            attempt.cancel()
            self.attempt = nil
            self.showFailureAlert()
            self.enableRetry()
        }
    }
    
    private func showFailureAlert() {
        let alert = UIAlertController(title: "Something unexpected happened".localized, message: "Sorry, we could not enroll you in CoLocate at this time. Please try again in a minute.".localized, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    private func enableRetry() {
        activityIndicator.stopAnimating()
        registerButton.isEnabled = true
    }
}

fileprivate let maxRegistrationSecs = 30.0
fileprivate let logger = Logger(label: "ViewController")
