//
//  StatusViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    enum Status {
        case initial, amber, red
    }

    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    private var notificationCenter: NotificationCenter!
    private var contactEventsUploader: ContactEventsUploader!
    private var linkingIdManager: LinkingIdManager!

    private lazy var drawerPresentationManager = DrawerPresentation()
    
    @IBOutlet var registratonStatusView: UIView!
    @IBOutlet var registrationStatusIcon: UIImageView!
    @IBOutlet var registrationSpinner: UIActivityIndicatorView!
    @IBOutlet var registrationStatusText: UILabel!
    @IBOutlet var registrationRetryButton: UIButton!

    @IBOutlet weak var symptomStackView: SymptomStackView!
    @IBOutlet weak var diagnosisStatusView: UIView!
    @IBOutlet weak var diagnosisHighlightView: UIView!
    @IBOutlet weak var diagnosisTitleLabel: UILabel!
    @IBOutlet weak var readLatestAdviceLabel: UILabel!

    @IBOutlet weak var howAreYouFeelingView: UIView!
    @IBOutlet weak var notRightView: UIView!
    @IBOutlet weak var notRightTitleLabel: UILabel!
    @IBOutlet weak var notRightSubtitleLabel: UILabel!
    @IBOutlet weak var noSymptomsLabel: UILabel!

    @IBOutlet weak var linkingIdView: UIStackView!
    @IBOutlet weak var linkingIdButton: ButtonWithDynamicType!

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
            switch (diagnosis?.isAffected, potentiallyExposed) {
            case (.some(true), _):
                return .red
            case (_, .some(true)):
                return .amber
            default:
                return .initial
            }
        }
    }
    
    func inject(
        persistence: Persisting,
        registrationService: RegistrationService,
        contactEventsUploader: ContactEventsUploader,
        notificationCenter: NotificationCenter,
        linkingIdManager: LinkingIdManager
    ) {
        self.persistence = persistence
        self.registrationService = registrationService
        self.contactEventsUploader = contactEventsUploader
        self.notificationCenter = notificationCenter
        self.linkingIdManager = linkingIdManager
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        registrationRetryButton.setTitle("RETRY".localized, for: .normal)

        diagnosisStatusView.layer.cornerRadius = 16
        diagnosisStatusView.layer.masksToBounds = true
        readLatestAdviceLabel.textColor = UIColor(named: "NHS Link")
        diagnosisStatusView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(diagnosisStatusTapped))
        )

        notRightView.layer.cornerRadius = 16
        notRightTitleLabel.textColor = UIColor(named: "NHS Link")
        notRightSubtitleLabel.textColor = UIColor(named: "NHS Secondary Text")
        notRightView.accessibilityLabel = "\(notRightTitleLabel.text!) \(notRightSubtitleLabel.text!)"
        notRightView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(notRightTapped))
        )

        noSymptomsLabel.textColor = UIColor(named: "NHS Secondary Text")

        #if PILOT
        linkingIdView.isHidden = false
        #else
        linkingIdView.isHidden = true
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            register()
        }
        
        notificationCenter.addObserver(self, selector: #selector(showRegisteredStatus), name: RegistrationCompletedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showRegistrationFailedStatus), name: RegistrationFailedNotification, object: nil)

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
        let navigationController = UINavigationController()
        let coordinator = SelfDiagnosisCoordinator(
            navigationController: navigationController,
            persisting: persistence,
            contactEventRepository: contactEventRepo,
            session: session
        )
        coordinator.start()
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    @IBAction func linkingIdButtonTapped(_ sender: ButtonWithDynamicType) {
        let vc = LinkingIdViewController.instantiate()
        vc.inject(persisting: persistence, linkingIdManager: linkingIdManager)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = drawerPresentationManager
        present(vc, animated: true)
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

    func renderStatus() {
        guard view != nil else { return }
        
        switch status {
            case .initial:
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Highlight")
                diagnosisTitleLabel.text = "Keep following the current government advice".localized
                howAreYouFeelingView.isHidden = false
            case .amber:
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
                diagnosisTitleLabel.text = "You have been near someone who has coronavirus symptoms".localized
                howAreYouFeelingView.isHidden = false
            case .red:
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Error")
                diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus".localized
                howAreYouFeelingView.isHidden = true
        }
        
        symptomStackView.symptoms = diagnosis?.symptoms
        diagnosisStatusView.accessibilityLabel = "\(diagnosisTitleLabel.text!) \(readLatestAdviceLabel.text!)"
        
        if let diagnosis = diagnosis {
            if diagnosis.hasExpired() {
                let symptomsPromptViewController = SymptomsPromptViewController.instantiate()
                symptomsPromptViewController.modalPresentationStyle = .custom
                symptomsPromptViewController.transitioningDelegate = drawerPresentationManager
                symptomsPromptViewController.inject(persistence: persistence, session: session, statusViewController: self)
                present(symptomsPromptViewController, animated: true)
            }
        }
    }
    
    func updatePrompt() {
        let coughUpdateViewController = CoughUpdateViewController.instantiate()
        coughUpdateViewController.modalPresentationStyle = .custom
        coughUpdateViewController.transitioningDelegate = drawerPresentationManager
        present(coughUpdateViewController, animated: true)
    }
    
    private func register() {
        showRegisteringStatus()
        registrationService.register()
    }
    
    @objc private func showRegisteredStatus() {
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        hideSpinner()
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registratonStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }
    
    @objc private func showRegistrationFailedStatus() {
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
