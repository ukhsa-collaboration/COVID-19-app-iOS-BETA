//
//  RegistrationStatusViewController.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

class RegistrationStatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "RegistrationStatus"

    @IBOutlet weak var registrationRetryButton: ButtonWithDynamicType!
    @IBOutlet weak var registrationStatusText: UILabel!
    @IBOutlet weak var registrationStatusIcon: UIImageView!
    @IBOutlet weak var registrationSpinner: SpinnerView!

    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    private var notificationCenter: NotificationCenter!

    func inject(
        persistence: Persisting,
        registrationService: RegistrationService,
        notificationCenter: NotificationCenter
    ) {
        self.persistence = persistence
        self.registrationService = registrationService
        self.notificationCenter = notificationCenter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

        registrationRetryButton.setTitle("RETRY".localized, for: .normal)

        notificationCenter.addObserver(self, selector: #selector(showRegisteredStatus), name: RegistrationCompletedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showRegistrationFailedStatus), name: RegistrationFailedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            logger.info("Attempting to register because the view will appear")
            register()
        }
    }

    @IBAction func retryRegistrationTapped() {
        logger.info("Attempting to register because the user tapped the retry button")
        register()
    }

    private func showSpinner() {
        registrationSpinner.isHidden = false
        registrationStatusIcon.isHidden = true
    }

    private func hideSpinner() {
        registrationSpinner.isHidden = true
        registrationStatusIcon.isHidden = false
    }

    private func register() {
        showRegisteringStatus()
        registrationService.register()
    }

    private func showRegisteringStatus() {
        registrationStatusText.text = "REGISTRATION_IN_PROGRESS".localized
        showSpinner()
        registrationStatusText.textColor = UIColor.nhs.text
        view.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }

    @objc private func showRegisteredStatus() {
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        hideSpinner()
        registrationStatusText.textColor = UIColor.nhs.text
        view.backgroundColor = nil
        registrationRetryButton.isHidden = true

        UIAccessibility.post(notification: .layoutChanged, argument: view)
    }

    @objc private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_failure")
        hideSpinner()
        registrationStatusText.textColor = UIColor.white
        view.backgroundColor = UIColor.nhs.errorGrey
        registrationRetryButton.isHidden = false

        UIAccessibility.post(notification: .layoutChanged, argument: view)
    }

}

private let logger = Logger(label: "RegistrationStatusViewController")
