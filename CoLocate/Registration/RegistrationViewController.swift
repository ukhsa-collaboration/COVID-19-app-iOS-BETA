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

    var registrationService: RegistrationService = ConcreteRegistrationService()

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
        sender.isEnabled = false

        registrationService.register { [weak self] result in
            guard let self = self else { return }

            self.activityIndicator.stopAnimating()

            if case .failure(let error) = result {
                print("\(#file) \(#function) Unable to register: \(error)")
                let alert = UIAlertController(title: "Registration failed", message: "\(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                
                sender.isEnabled = true
            }
        }
    }
}
