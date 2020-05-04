//
//  StatusViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    private let content = StatusContent.shared
    private var persistence: Persisting!
    private var registrationService: RegistrationService!
    private var notificationCenter: NotificationCenter!
    private var contactEventsUploader: ContactEventsUploading!
    private var linkingIdManager: LinkingIdManaging!
    private var statusProvider: StatusProviding!
    private var localeProvider: LocaleProvider!

    private lazy var drawerPresentationManager = DrawerPresentation()
    private let localNotificationScheduler = LocalNotifcationScheduler(userNotificationCenter: UNUserNotificationCenter.current())
    
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
    @IBOutlet weak var diagnosisDetailLabel: UILabel!
    @IBOutlet weak var disclosureIndicator: UIImageView!
    
    @IBOutlet weak var howAreYouFeelingView: UIView!
    @IBOutlet weak var notRightView: UIView!
    @IBOutlet weak var notRightTitleLabel: UILabel!
    @IBOutlet weak var notRightSubtitleLabel: UILabel!
    
    @IBOutlet weak var nothingToDoLabel: UILabel!
    @IBOutlet weak var noSymptomsLabel: UILabel!

    @IBOutlet weak var redStatusView: UIStackView!
    @IBOutlet weak var healthcareWorkersInstructionsView: UIControl!

    @IBOutlet weak var linkingIDButton: UIButton!
    @IBOutlet weak var nhs111label: ButtonWithDynamicType!
    @IBOutlet weak var medicalAdviceLabel: UILabel!
    
    func inject(
        persistence: Persisting,
        registrationService: RegistrationService,
        contactEventsUploader: ContactEventsUploading,
        notificationCenter: NotificationCenter,
        linkingIdManager: LinkingIdManaging,
        statusProvider: StatusProviding,
        localeProvider: LocaleProvider
    ) {
        self.persistence = persistence
        self.registrationService = registrationService
        self.contactEventsUploader = contactEventsUploader
        self.notificationCenter = notificationCenter
        self.linkingIdManager = linkingIdManager
        self.statusProvider = statusProvider
        self.localeProvider = localeProvider
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        registrationRetryButton.setTitle("RETRY".localized, for: .normal)

        diagnosisStatusView.layer.cornerRadius = 8
        diagnosisStatusView.layer.masksToBounds = true
        readLatestAdviceLabel.textColor = UIColor(named: "NHS Link")

        medicalAdviceLabel.textColor = UIColor(named: "NHS Secondary Text")

        diagnosisStatusView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(diagnosisStatusTapped))
        )
        
        nhs111label.setAttributedTitle(
            NSAttributedString(
                string: "NHS Coronavirus".localized,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor(named: "NHS Link")!,
                    .font: UIFont.preferredFont(forTextStyle: .body),
                ]
            ),
            for: .normal)

        notRightView.layer.cornerRadius = 8
        notRightSubtitleLabel.textColor = UIColor(named: "NHS Secondary Text")
        notRightTitleLabel.textColor = UIColor(named: "NHS Text")
        notRightView.layer.borderColor = UIColor(named: "NHS Highlight")!.withAlphaComponent(0.96).cgColor
        notRightView.accessibilityLabel = "\(notRightTitleLabel.text!) \(notRightSubtitleLabel.text!)"

        noSymptomsLabel.textColor = UIColor(named: "NHS Secondary Text")
        nothingToDoLabel.textColor = UIColor(named: "NHS Secondary Text")

        readLatestAdviceLabel.accessibilityHint = "Opens in your browser".localized
        readLatestAdviceLabel.accessibilityTraits = .link

        nhs111label.accessibilityHint = "Opens in your browser".localized
        nhs111label.accessibilityTraits = .link

        healthcareWorkersInstructionsView.accessibilityLabel = "Important instructions for healthcare workers"
        healthcareWorkersInstructionsView.accessibilityTraits = .button
        
        notificationCenter.addObserver(self, selector: #selector(showRegisteredStatus), name: RegistrationCompletedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showRegistrationFailedStatus), name: RegistrationFailedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(reload), name: PotentiallyExposedNotification, object: nil)
        
        linkingIDButton.accessibilityLabel = "Show my reference code"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)


        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            register()
        }

        reload()
    }

    @objc func diagnosisStatusTapped() {
        UIApplication.shared.open(content[statusProvider.status].readUrl)
    }

    @IBAction func notRightTapped() {
        let navigationController = UINavigationController()
        let coordinator = SelfDiagnosisCoordinator(
            navigationController: navigationController,
            persisting: persistence,
            contactEventsUploader: contactEventsUploader,
            statusViewController: self,
            localNotificationScheduler: localNotificationScheduler
        )
        coordinator.start()
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    @IBAction func medicalWorkerButtonTapped() {
        let vc = MedicalWorkerInstructionsViewController.instantiate()
        showDrawer(vc)
    }

    @IBAction func linkingIdButtonTapped() {
        let vc = LinkingIdViewController.instantiate()
        vc.inject(persisting: persistence, linkingIdManager: linkingIdManager)
        showDrawer(vc)
    }

    private func showDrawer(_ vc: UIViewController) {
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = drawerPresentationManager
        present(vc, animated: true)
    }

    @IBAction func nhs111Tapped(_ sender: UIButton) {
        UIApplication.shared.open(content[statusProvider.status].nhsCoronavirusUrl)
    }

    @IBAction func retryRegistrationTapped() {
        register()
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        reload()
    }

    @IBAction func unwindFromLinkingId(unwindSegue: UIStoryboardSegue) {
    }

    @objc func reload() {
        guard view != nil else { return }
        
        let readLatestAdviceText: String
        if statusProvider.status == .blue {
            readLatestAdviceText = "Read current advice"
        } else {
            readLatestAdviceText = "Read what to do next"
        }
        readLatestAdviceLabel.attributedText = NSAttributedString(
            string: readLatestAdviceText.localized,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor(named: "NHS Link")!,
                .font: UIFont.preferredFont(forTextStyle: .body),
            ]
        )
        
        switch statusProvider.status {
            case .blue:
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Highlight")
                diagnosisTitleLabel.text = "Follow the current advice to stop the spread of coronavirus".localized
                diagnosisDetailLabel.isHidden = true
                howAreYouFeelingView.isHidden = false
                nothingToDoLabel.isHidden = false
                redStatusView.isHidden = true
                healthcareWorkersInstructionsView.isHidden = false
            case .amber:
                nothingToDoLabel.isHidden = true
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
                diagnosisTitleLabel.text = "You have been near someone who has coronavirus symptoms".localized
                
                if let expiry = statusProvider.amberExpiryDate {
                    diagnosisDetailLabel.isHidden = false
                    diagnosisDetailLabel.text = detailForAmberWithExpiry(expiry)
                } else {
                    diagnosisDetailLabel.isHidden = true
                }
                
                howAreYouFeelingView.isHidden = false
                redStatusView.isHidden = true
                healthcareWorkersInstructionsView.isHidden = false
            case .red:
                diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
                diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus".localized
                diagnosisDetailLabel.isHidden = false

                if let selfDiagnosis = persistence.selfDiagnosis {
                    switch selfDiagnosis.type {
                    case .initial:
                        detailForInitialSelfDiagnosis(selfDiagnosis)
                    case .subsequent:
                        if selfDiagnosis.symptoms.contains(.temperature) {
                            diagnosisDetailLabel.text = "Follow this advice until your temperature returns to normal"
                        }
                    }
                } else {
                    // Can't happen, but don't show the placeholder text if it does.
                    diagnosisDetailLabel.isHidden = true
                }
                
                howAreYouFeelingView.isHidden = true
                redStatusView.isHidden = false
                healthcareWorkersInstructionsView.isHidden = true
        }
        
        symptomStackView.symptoms = persistence.selfDiagnosis?.symptoms
        
        if let diagnosis = persistence.selfDiagnosis, diagnosis.hasExpired() {
            localNotificationScheduler.removePendingDiagnosisNotification()
            let symptomsPromptViewController = SymptomsPromptViewController.instantiate()
            symptomsPromptViewController.modalPresentationStyle = .custom
            symptomsPromptViewController.transitioningDelegate = drawerPresentationManager
            symptomsPromptViewController.inject(persistence: persistence, statusViewController: self)
            present(symptomsPromptViewController, animated: true)
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

        UIAccessibility.post(notification: .layoutChanged, argument: registratonStatusView)
    }
    
    @objc private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_failure")
        hideSpinner()
        registrationStatusText.textColor = UIColor.white
        registratonStatusView.backgroundColor = UIColor(named: "Error Grey")
        registrationRetryButton.isHidden = false

        UIAccessibility.post(notification: .layoutChanged, argument: registratonStatusView)
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
    
    private func detailForAmberWithExpiry(_ expiry: Date) -> String {
        let detailFmt = "Follow this advice until %@".localized
        return String(format: detailFmt, localizedDate(expiry))
    }
    
    private func detailForInitialSelfDiagnosis(_ selfDiagnosis: SelfDiagnosis) {
        let detailFmt = "Follow this advice until %@, at which point this app will notify you to update your symptoms.".localized
        diagnosisDetailLabel.text = String(format: detailFmt, localizedDate(selfDiagnosis.expiryDate))
    }
    
    private func localizedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = localeProvider.locale
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return dateFormatter.string(from: date)
    }
}

private let logger = Logger(label: "StatusViewController")

class TouchCancellingScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}

