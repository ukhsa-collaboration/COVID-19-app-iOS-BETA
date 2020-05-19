//
//  StatusViewController.swift
//  Sonar
//
//  Created by NHSX on 17.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    @IBOutlet weak var contentStackView: UIStackView!
    
    @IBOutlet weak var registrationStatusViewContainer: UIView!
    @IBOutlet weak var registrationRetryButton: ButtonWithDynamicType!
    @IBOutlet weak var registrationStatusText: UILabel!
    @IBOutlet weak var registrationStatusIcon: UIImageView!
    @IBOutlet weak var registrationSpinner: SpinnerView!
    @IBOutlet weak var registrationStatusView: UIView!
    
    @IBOutlet weak var notificationsStatusView: UIView!
    @IBOutlet weak private var disableNotificationStatusViewButton: NotificationStatusButton!
    @IBOutlet weak private var goToSettingsButton: NotificationStatusButton!
    
    @IBOutlet weak var diagnosisHighlightView: UIView!
    @IBOutlet weak var diagnosisTitleLabel: UILabel!
    @IBOutlet weak var diagnosisDetailLabel: UILabel!

    @IBOutlet weak var feelUnwellButton: UIButton!
    @IBOutlet weak var feelUnwellTitleLabel: UILabel!
    @IBOutlet weak var feelUnwellBodyLabel: UILabel!

    @IBOutlet weak var applyForTestButton: UIButton!
    @IBOutlet weak var stepsDetailLabel: UILabel!

    var hasNotificationProblem = false {
        didSet {
            setupBannerAppearance(hasNotificationProblem: hasNotificationProblem,
                                  bannerDisabled: persistence.disabledNotificationsStatusView)
        }
    }
    
    private let content = ContentURLs.shared
    private lazy var drawerPresentationManager = DrawerPresentation()
    private var dateProvider: (() -> Date)!
    
    private var userStatusProvider: UserStatusProvider!
    private var persistence: Persisting!
    private var statusStateMachine: StatusStateMachining!
    private var linkingIdManager: LinkingIdManaging!
    private var registrationService: RegistrationService!
    private var notificationCenter: NotificationCenter!
    private var urlOpener: TestableUrlOpener!
    
    func inject(statusStateMachine: StatusStateMachining, userStatusProvider: UserStatusProvider, persistence: Persisting, linkingIdManager: LinkingIdManaging, registrationService: RegistrationService, dateProvider: @escaping () -> Date = { Date() }, notificationCenter: NotificationCenter, urlOpener: TestableUrlOpener
) {
        self.linkingIdManager = linkingIdManager
        self.statusStateMachine = statusStateMachine
        self.userStatusProvider = userStatusProvider
        self.persistence = persistence
        self.registrationService = registrationService
        self.dateProvider = dateProvider
        self.notificationCenter = notificationCenter
        self.urlOpener = urlOpener
    }

    override func viewDidLoad() {
        diagnosisHighlightView.layer.cornerRadius = 8
        registrationRetryButton.setTitle("RETRY".localized, for: .normal)

        feelUnwellButton.accessibilityLabel = [
            feelUnwellTitleLabel.text, feelUnwellBodyLabel.text
        ].compactMap { $0 }.joined(separator: ". ")

        let logo = UIImageView(image: UIImage(named: "NHS_Logo"))
        logo.contentMode = .scaleAspectFit
        diagnosisHighlightView.accessibilityIgnoresInvertColors = true
        
        setupBannerAppearance(hasNotificationProblem: hasNotificationProblem,
                              bannerDisabled: persistence.disabledNotificationsStatusView)
                
        goToSettingsButton.titleLabel?.text = "GO_TO_SETTINGS".localized
        disableNotificationStatusViewButton.titleLabel?.text = "DISABLE_NOTIFICATIONS_STATUS_VIEW".localized

        let title = UILabel()
        title.text = "COVID-19"
        title.textColor = UIColor(named: "NHS Blue")
        title.accessibilityLabel = "NHS Covid 19"

        let stack = UIStackView()
        stack.addArrangedSubview(logo)
        stack.addArrangedSubview(title)

        navigationItem.titleView = stack
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info"), style: .plain, target: self, action: #selector(infoTapped))
        
        notificationCenter.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(reload), name: StatusStateMachine.StatusStateChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showRegisteredStatus), name: RegistrationCompletedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showRegistrationFailedStatus), name: RegistrationFailedNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ApplyForTestContainerViewController {
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: DispatchQueue.main, urlOpener: urlOpener)
        }
    }
    private func setupBannerAppearance(hasNotificationProblem: Bool, bannerDisabled: Bool) {
        guard isViewLoaded else { return }
        let hideBanner = !hasNotificationProblem || bannerDisabled
        
        notificationsStatusView?.isHidden = hideBanner
        
        let spacing = hideBanner ? UIStackView.spacingUseDefault : 0
        contentStackView.setCustomSpacing(spacing, after: registrationStatusViewContainer)
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
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registrationStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true
    }

    @objc private func showRegisteredStatus() {
        registrationStatusText.text = "REGISTRATION_OK".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_ok")
        hideSpinner()
        registrationStatusText.textColor = UIColor(named: "NHS Text")
        registrationStatusView.backgroundColor = nil
        registrationRetryButton.isHidden = true

        UIAccessibility.post(notification: .layoutChanged, argument: registrationStatusView)
    }

    @objc private func showRegistrationFailedStatus() {
        registrationStatusText.text = "REGISTRATION_FAILED".localized
        registrationStatusIcon.image = UIImage(named: "Registration_status_failure")
        hideSpinner()
        registrationStatusText.textColor = UIColor.white
        registrationStatusView.backgroundColor = UIColor(named: "Error Grey")
        registrationRetryButton.isHidden = false

        UIAccessibility.post(notification: .layoutChanged, argument: registrationStatusView)
    }

    override func viewWillAppear(_ animated: Bool) {
        if persistence.registration != nil {
            showRegisteredStatus()
        } else {
            logger.info("Attempting to register because the view will appear")
            register()
        }

        reload()
    }

    @objc func infoTapped() {
        UIApplication.shared.open(ContentURLs.shared.statusInfo)
    }

    @IBAction func retryRegistrationTapped() {
        logger.info("Attempting to register because the user tapped the retry button")
        register()
    }

    @IBAction func adviceTapped(_ sender: Any) {
        let adviceVc = AdviceViewController.instantiate()
        adviceVc.inject(linkDestination: content.currentAdvice(for: statusStateMachine.state))
        navigationController?.pushViewController(adviceVc, animated: true)
    }

    @IBAction func feelUnwellTapped(_ sender: Any) {
        let coordinator = SelfDiagnosisCoordinator(
            navigationController: navigationController!,
            statusStateMachine: statusStateMachine
        ) { symptoms in
            self.navigationController?.popToViewController(self, animated: true)

            if symptoms.contains(.cough), case .ok = self.statusStateMachine.state {
                self.presentCoughUpdate()
            }
        }

        coordinator.start()
    }

    @IBAction func applyForTestTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showApplyForTest", sender: self)
    }

    @IBAction func testingInfoTapped(_ sender: Any) {
        let linkingIdVc = TestingInfoContainerViewController.instantiate()
        linkingIdVc.inject(linkingIdManager: linkingIdManager, uiQueue: DispatchQueue.main)
        navigationController?.pushViewController(linkingIdVc, animated: true)
    }

    @IBAction func workplaceGuidanceTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showWorkplaceGuidance", sender: self)
    }

    fileprivate func presentPrompt(for checkin: StatusState.Checkin) {
        let symptomsPromptViewController = SymptomsPromptViewController.instantiate()
        symptomsPromptViewController.modalPresentationStyle = .custom
        symptomsPromptViewController.transitioningDelegate = drawerPresentationManager
        symptomsPromptViewController.inject { needsCheckin in
            self.dismiss(animated: true)

            if needsCheckin {
                let coordinator = CheckinCoordinator(
                    navigationController: self.navigationController!,
                    checkin: checkin
                ) { symptoms in
                    self.statusStateMachine.checkin(symptoms: symptoms)
                        
                    self.navigationController!.popToRootViewController(animated: true)

                    if symptoms.contains(.cough), case .ok = self.statusStateMachine.state {
                        self.presentCoughUpdate()
                    }
                }
                coordinator.start()
            } else {
                self.statusStateMachine.checkin(symptoms: [])
            }
        }
        present(symptomsPromptViewController, animated: true)
    }

    @IBAction func goToSettingsTapped() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }
    
    @IBAction func disableNotificationsTapped() {
        persistence.disabledNotificationsStatusView = true
        setupBannerAppearance(hasNotificationProblem: hasNotificationProblem,
                              bannerDisabled: persistence.disabledNotificationsStatusView)

        let title = "NOTIFICATIONS_DISABLED_ALERT_TITLE".localized
        let message = "NOTIFICATIONS_DISABLED_ALERT_MESSAGE".localized
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "NOTIFICATIONS_DISABLED_ALERT_OK".localized, style: .default)
        alertController.addAction(alertAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func reload() {
        guard view != nil else { return }

        statusStateMachine.tick()

        switch statusStateMachine.state {
        case .ok:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
            diagnosisTitleLabel.text = "Follow the current advice to stop the spread of coronavirus"
            diagnosisDetailLabel.isHidden = true
            feelUnwellButton.isHidden = false
            applyForTestButton.isHidden = true
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "If you don’t have any symptoms, there’s no need to do anything right now. If you develop symptoms, please come back to this app."

        case .exposed:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "You have been near someone who has coronavirus symptoms"
            diagnosisDetailLabel.text = "Mantain social distancing and wash your hands frequently. Read advice for you below."
            diagnosisDetailLabel.isHidden = false
            feelUnwellButton.isHidden = false
            applyForTestButton.isHidden = true
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "If you develop symptoms, please come back to this app."

        case .symptomatic(let symptomatic):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."
            diagnosisDetailLabel.isHidden = false
            diagnosisDetailLabel.text = userStatusProvider.detailForSymptomatic(symptomatic.expiryDate)
            feelUnwellButton.isHidden = true
            applyForTestButton.isHidden = false
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"

        case .checkin(let checkin):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."
            diagnosisDetailLabel.isHidden = false
            diagnosisDetailLabel.text = "Follow this advice until your temperature returns to normal."
            feelUnwellButton.isHidden = true
            applyForTestButton.isHidden = false
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"

            if dateProvider() >= checkin.checkinDate {
                presentPrompt(for: checkin)
            }
        }
    }

    private func presentCoughUpdate() {
        let coughUpdateViewController = CoughUpdateViewController.instantiate()
        coughUpdateViewController.modalPresentationStyle = .custom
        coughUpdateViewController.transitioningDelegate = drawerPresentationManager
        navigationController?.visibleViewController!.present(coughUpdateViewController, animated: true)
    }
}

private let logger = Logger(label: "StatusViewController")

class TouchCancellingScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}
