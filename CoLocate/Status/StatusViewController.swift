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
    
    @IBOutlet var registratonStatusView: UIView!
    @IBOutlet var registrationStatusIcon: UIImageView!
    @IBOutlet var registrationSpinner: UIActivityIndicatorView!
    @IBOutlet var registrationStatusText: UILabel!
    @IBOutlet var registrationRetryButton: UIButton!

    @IBOutlet weak var diagnosisStatusView: UIView!
    @IBOutlet weak var diagnosisHighlightView: UIView!
    @IBOutlet weak var diagnosisTitleLabel: UILabel!
    @IBOutlet weak var readLatestAdviceLabel: UILabel!

    @IBOutlet weak var howAreYouFeelingView: UIView!
    @IBOutlet weak var feelHealthyView: UIView!
    @IBOutlet weak var feelHealthyTitleLabel: UILabel!
    @IBOutlet weak var feelHealthySubtitleLabel: UILabel!
    @IBOutlet weak var notRightView: UIView!
    @IBOutlet weak var notRightTitleLabel: UILabel!
    @IBOutlet weak var notRightSubtitleLabel: UILabel!

    @IBOutlet weak var nextStepsView: UIView!

    var diagnosis: Diagnosis? {
        didSet {
            guard view != nil else { return }

            switch diagnosis {
            case .none, .some(.notInfected):
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
                diagnosisTitleLabel.text = "Keep following the current government advice".localized
                howAreYouFeelingView.isHidden = false
                nextStepsView.isHidden = true
            case .some(.potential):
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
                diagnosisTitleLabel.text = "You have been near someone who has coronavirus symptoms".localized
                howAreYouFeelingView.isHidden = false
                nextStepsView.isHidden = true
            case .some(.infected):
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Error")
                diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus".localized
                howAreYouFeelingView.isHidden = true
                nextStepsView.isHidden = false
            }

            diagnosisStatusView.accessibilityLabel = "\(diagnosisTitleLabel.text!) \(readLatestAdviceLabel.text!)"
        }
    }
    
    func inject(persistence: Persisting, registrationService: RegistrationService, mainQueue: AsyncAfterable) {
        self.persistence = persistence
        self.registrationService = registrationService
        self.mainQueue = mainQueue
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registrationRetryButton.setTitle("RETRY".localized, for: .normal)

        diagnosisStatusView.layer.cornerRadius = 16
        diagnosisStatusView.layer.masksToBounds = true
        readLatestAdviceLabel.textColor = UIColor(named: "NHS Blue")
        diagnosisStatusView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(diagnosisStatusTapped))
        )

        feelHealthyView.layer.cornerRadius = 16
        feelHealthyTitleLabel.textColor = UIColor(named: "NHS Blue")
        feelHealthySubtitleLabel.textColor = UIColor(named: "NHS Grey 1")

        notRightView.layer.cornerRadius = 16
        notRightTitleLabel.textColor = UIColor(named: "NHS Blue")
        notRightSubtitleLabel.textColor = UIColor(named: "NHS Grey 1")
        notRightView.accessibilityLabel = "\(notRightTitleLabel.text!) \(notRightSubtitleLabel.text!)"
        notRightView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(notRightTapped))
        )

        nextStepsView.isHidden = true

        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            register()
        }

        diagnosis = persistence.diagnosis
    }

    @objc func diagnosisStatusTapped() {
        let alert = UIAlertController(title: nil, message: "reading latest advice", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "okay", style: .default))
        present(alert, animated: true)
    }

    @objc func notRightTapped() {
        let selfDiagnosis = SelfDiagnosisNavigationController.instantiate()
        present(selfDiagnosis, animated: true)
    }

    @IBAction func retryRegistrationTapped() {
        register()
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        diagnosis = persistence.diagnosis
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
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        hideSpinner()
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }
    
    private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_failure")
        hideSpinner()
        registrationStatusText.textColor = UIColor.white
        registratonStatusView.backgroundColor = UIColor(named: "Error Grey")
        registrationRetryButton.isHidden = false
    }
    
    private func showRegisteringStatus() {
        registrationStatusText.text = "REGISTRATION_IN_PROGRESS".localized
        showSpinner()
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }
    
    private func showSpinner() {
        registrationSpinner.startAnimating()
        registrationSpinner.isHidden = false
        registrationStatusIcon.isHidden = true
    }
    
    private func hideSpinner() {
        registrationSpinner.stopAnimating()
        registrationSpinner.isHidden = true
        registrationStatusIcon.isHidden = false
    }
}

private let logger = Logger(label: "StatusViewController")
