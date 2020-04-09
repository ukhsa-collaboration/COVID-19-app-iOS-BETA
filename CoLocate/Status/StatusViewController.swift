//
//  StatusViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    
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
    @IBOutlet private var checkSymptomsButton: PrimaryButton!
    
    func inject(persistence: Persisting, registrationService: RegistrationService) {
        self.persistence = persistence
        self.registrationService = registrationService
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
        
        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            showRegisteringStatus()
            
            registrationService.register() { [weak self] result in
                guard let self = self else { return }
                
                switch (result) {
                case .success():
                    self.showRegisteredStatus()
                case .failure(_):
                    self.showRegistrationFailedStatus()
                }
            }
        }
    }
    
    @IBAction func checkSymptomsTapped(_ sender: PrimaryButton) {
        let selfDiagnosis = SelfDiagnosisNavigationController.instantiate()
        present(selfDiagnosis, animated: true)
    }

    @IBAction func unwindFromOnboarding(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }
    
    private func showRegisteredStatus() {
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        registrationStatusIcon.isHidden = false
        registrationSpinner.isHidden = true
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
    }
    
    private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.isHidden = false
        registrationSpinner.isHidden = true
        registrationStatusText.textColor = UIColor.white
        registratonStatusView.backgroundColor = UIColor(named: "Error Grey")
    }
    
    private func showRegisteringStatus() {
        registrationStatusText.text = "REGISTRATION_IN_PROGRESS".localized
        registrationStatusIcon.isHidden = true
        registrationSpinner.isHidden = false
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
    }
}

