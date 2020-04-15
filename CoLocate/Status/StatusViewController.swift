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

    enum Status {
        case initial, amber, red
    }

    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    private var mainQueue: TestableQueue!
    private var contactEventRepo: ContactEventRepository!
    private var session: Session!
    
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

    var diagnosis: SelfDiagnosis? {
        didSet {
            renderStatus()
        }
    }
    var potentiallyExposed: Bool? {
        didSet {
            renderStatus()
        }
    }
    var status: Status {
        get {
            switch (diagnosis, potentiallyExposed) {
            case (.some(.infected), _):
                return .red
            case (_, .some(true)):
                return .amber
            default:
                return .initial
            }
        }
    }
    
    func inject(persistence: Persisting, registrationService: RegistrationService, mainQueue: TestableQueue, contactEventRepo: ContactEventRepository, session: Session) {
        
        self.persistence = persistence
        self.registrationService = registrationService
        self.mainQueue = mainQueue
        self.contactEventRepo = contactEventRepo
        self.session = session
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

        diagnosis = persistence.selfDiagnosis
        potentiallyExposed = persistence.potentiallyExposed
    }

    @objc func diagnosisStatusTapped() {
        let path: String
        switch status {
        case .initial:
            path = "full-guidance-on-staying-at-home-and-away-from-others/full-guidance-on-staying-at-home-and-away-from-others"
        case .amber, .red:
            path = "covid-19-stay-at-home-guidance/stay-at-home-guidance-for-households-with-possible-coronavirus-covid-19-infection"
        }
        let url = URL(string: "https://www.gov.uk/government/publications/\(path)")!
        UIApplication.shared.open(url)
    }

    @objc func notRightTapped() {
        let selfDiagnosis = SelfDiagnosisNavigationController.instantiate()
        selfDiagnosis.inject(persistence: persistence, contactEventRepo: contactEventRepo, session: session)
        present(selfDiagnosis, animated: true)
    }

    @IBAction func nhs111Tapped(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://111.nhs.uk/covid-19/")!)
    }

    @IBAction func retryRegistrationTapped() {
        register()
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        diagnosis = persistence.selfDiagnosis
    }

    private func renderStatus() {
        guard view != nil else { return }

        switch status {
        case .initial:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
            diagnosisTitleLabel.text = "Keep following the current government advice".localized
            howAreYouFeelingView.isHidden = false
            nextStepsView.isHidden = true
        case .amber:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "You have been near someone who has coronavirus symptoms".localized
            howAreYouFeelingView.isHidden = false
            nextStepsView.isHidden = true
        case .red:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Error")
            diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus".localized
            howAreYouFeelingView.isHidden = true
            nextStepsView.isHidden = false
        }

        diagnosisStatusView.accessibilityLabel = "\(diagnosisTitleLabel.text!) \(readLatestAdviceLabel.text!)"
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
