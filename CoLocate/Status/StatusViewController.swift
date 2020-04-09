//
//  StatusViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

fileprivate let registrationTimeLimitSecs = 20.0

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    private var mainQueue: AsyncAfterable!
    
    @IBOutlet private var warningView: UIView!
    @IBOutlet private var warningViewTitle: UILabel!
    @IBOutlet private var warningViewBody: UILabel!
    @IBOutlet private var checkSymptomsTitle: UILabel!
    @IBOutlet private var checkSymptomsBody: UILabel!
    @IBOutlet private var moreInformationTitle: UILabel!
    @IBOutlet private var moreInformationBody: UILabel!
    @IBOutlet var registratonStatusView: UIView!
    @IBOutlet var registrationStatusIcon: UIImageView!
    @IBOutlet var registrationSpinner: UIActivityIndicatorView!
    @IBOutlet var registrationStatusText: UILabel!
    @IBOutlet var registrationRetryButton: UIButton!
    @IBOutlet private var checkSymptomsButton: PrimaryButton!
    
    func inject(persistence: Persisting, registrationService: RegistrationService, mainQueue: AsyncAfterable) {
        self.persistence = persistence
        self.registrationService = registrationService
        self.mainQueue = mainQueue
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "NHS Grey 5")
    
        warningView.backgroundColor = UIColor(named: "NHS Purple")
        warningViewTitle.textColor = UIColor(named: "NHS White")
        warningViewBody.textColor = UIColor(named: "NHS White")

        warningViewTitle.text = "OK_NOW_TITLE".localized
        warningViewBody.text = "OK_NOW_MESSAGE".localized
        checkSymptomsTitle.text = "OK_NOW_SYMPTOMS_TITLE".localized
        checkSymptomsBody.text = "OK_NOW_SYMPTOMS_MESSAGE".localized
        checkSymptomsButton.setTitle("OK_NOW_SYMPTOMS_BUTTON".localized, for: .normal)
        moreInformationTitle.text = "OK_NOW_MORE_INFO_TITLE".localized
        moreInformationBody.text = "OK_NOW_MORE_INFO_MESSAGE".localized
        registrationRetryButton.setTitle("RETRY".localized, for: .normal)
        
        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            register()
        }
    }
    
    @IBAction func checkSymptomsTapped(_ sender: PrimaryButton) {
        let selfDiagnosis = SelfDiagnosisNavigationController.instantiate()
        present(selfDiagnosis, animated: true)
    }

    @IBAction func retryRegistrationTapped() {
        register()
    }
    
    @IBAction func unwindFromOnboarding(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }
    
    private func register() {
        showRegisteringStatus()
        var finished = false
        
        let attempt = registrationService.register() { [weak self] result in
            guard let self = self else { return }
            
            finished = true
            
            switch (result) {
            case .success():
                self.showRegisteredStatus()
            case .failure(_):
                self.showRegistrationFailedStatus()
            }
        }
        
        mainQueue.asyncAfter(deadline: .now() + registrationTimeLimitSecs) { [weak self] in
            guard let self = self, !finished else { return }
            
            logger.error("Registration did not complete within \(registrationTimeLimitSecs) seconds")
            attempt.cancel()
            self.showRegistrationFailedStatus()
        }
    }
    
    private func showRegisteredStatus() {
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        registrationStatusIcon.isHidden = false
        registrationSpinner.isHidden = true
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }
    
    private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_failure")
        registrationStatusIcon.isHidden = false
        registrationSpinner.isHidden = true
        registrationStatusText.textColor = UIColor.white
        registratonStatusView.backgroundColor = UIColor(named: "Error Grey")
        registrationRetryButton.isHidden = false
        
    }
    
    private func showRegisteringStatus() {
        registrationStatusText.text = "REGISTRATION_IN_PROGRESS".localized
        registrationStatusIcon.isHidden = true
        registrationSpinner.isHidden = false
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
        
    }
}

private let logger = Logger(label: "StatusViewController")
