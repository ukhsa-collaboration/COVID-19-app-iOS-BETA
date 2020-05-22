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
    @IBOutlet weak var notificationsStatusView: UIView!
    @IBOutlet weak private var disableNotificationStatusViewButton: NotificationStatusButton!
    @IBOutlet weak private var goToSettingsButton: NotificationStatusButton!
    
    @IBOutlet weak var diagnosisStackView: UIStackView!
    @IBOutlet weak var diagnosisHighlightView: UIView!
    @IBOutlet weak var diagnosisTitleLabel: UILabel!
    @IBOutlet weak var diagnosisDetailLabel: UILabel!

    @IBOutlet weak var nextStepsDetailView: UIView!

    @IBOutlet weak var feelUnwellButton: UIButton!
    @IBOutlet weak var feelUnwellTitleLabel: UILabel!
    @IBOutlet weak var feelUnwellBodyLabel: UILabel!

    @IBOutlet weak var applyForTestButton: UIButton!
    @IBOutlet weak var stepsDetailLabel: UILabel!

    @IBOutlet weak var nhsServicesStackView: UIStackView!
    @IBOutlet weak var nhsCoronavirusLinkButton: LinkButton!

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
    
    func inject(statusStateMachine: StatusStateMachining, userStatusProvider: UserStatusProvider, persistence: Persisting, linkingIdManager: LinkingIdManaging, registrationService: RegistrationService, dateProvider: @escaping () -> Date = { Date() }, notificationCenter: NotificationCenter
    ) {
        self.linkingIdManager = linkingIdManager
        self.statusStateMachine = statusStateMachine
        self.userStatusProvider = userStatusProvider
        self.persistence = persistence
        self.registrationService = registrationService
        self.dateProvider = dateProvider
        self.notificationCenter = notificationCenter
    }

    override func viewDidLoad() {
        // Pre-iOS 13, we can’t customise large content.
        // Set the title, so the OS has _something_ to show.
        navigationItem.title = "NHS COVID-19"
        
        navigationItem.titleView = {
            let logo = UIImageView(image: UIImage(named: "NHS_Logo"))
            logo.contentMode = .scaleAspectFit

            let title = UILabel()
            title.text = "COVID-19"
            title.textColor = UIColor(named: "NHS Blue")

            let stack = UIStackView(arrangedSubviews: [logo, title])
            stack.accessibilityLabel = "NHS Covid 19"

            if #available(iOS 13.0, *) {
                stack.showsLargeContentViewer = true
                stack.largeContentImage = UIImage(named: "NHS-Logo-Template")
                stack.largeContentTitle = "COVID-19"
                stack.addInteraction(UILargeContentViewerInteraction())
            }

            return stack
        }()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info"), style: .plain, target: self, action: #selector(infoTapped))

        diagnosisHighlightView.layer.cornerRadius = 8
        diagnosisHighlightView.accessibilityIgnoresInvertColors = true

        setupBannerAppearance(hasNotificationProblem: hasNotificationProblem,
                              bannerDisabled: persistence.disabledNotificationsStatusView)
                
        goToSettingsButton.titleLabel?.text = "GO_TO_SETTINGS".localized
        disableNotificationStatusViewButton.titleLabel?.text = "DISABLE_NOTIFICATIONS_STATUS_VIEW".localized

        feelUnwellButton.accessibilityLabel = [
            feelUnwellTitleLabel.text, feelUnwellBodyLabel.text
        ].compactMap { $0 }.joined(separator: ". ")

        diagnosisStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.setCustomSpacing(32, after: diagnosisStackView)
        contentStackView.setCustomSpacing(32, after: nextStepsDetailView)
        nhsServicesStackView.isLayoutMarginsRelativeArrangement = true

        nhsCoronavirusLinkButton.url = ContentURLs.shared.regionalServices

        notificationCenter.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(stateChanged(_:)), name: StatusStateMachine.StatusStateChangedNotification, object: nil)
    }
    
    @objc func stateChanged(_ statusStateMachineNotification: NSNotification) {
        defer { reload() } // Always reload when the statusStateMachine's state changes
        
        guard let statusStateMachine = statusStateMachineNotification.object as? StatusStateMachine else { return }
        switch statusStateMachine.state {
        case .positiveTestResult:
            presentTestResultUpdate(result: .positive)
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as RegistrationStatusViewController:
            vc.inject(persistence: persistence, registrationService: registrationService, notificationCenter: notificationCenter)
        case let vc as ApplyForTestContainerViewController:
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: DispatchQueue.main)
        case let vc as DrawerViewController:
            guard let config = sender as? DrawerViewController.Config else {
                assertionFailure("DrawerViewControllers need configuration")
                return
            }
            vc.inject(config: config)
        default:
            break
        }
    }

    private func setupBannerAppearance(hasNotificationProblem: Bool, bannerDisabled: Bool) {
        guard isViewLoaded else { return }
        let hideBanner = !hasNotificationProblem || bannerDisabled
        
        notificationsStatusView?.isHidden = hideBanner
        
        let spacing = hideBanner ? UIStackView.spacingUseDefault : 0
        contentStackView.setCustomSpacing(spacing, after: registrationStatusViewContainer)
   }

    override func viewWillAppear(_ animated: Bool) {
        reload()
    }

    @objc func infoTapped() {
        UIApplication.shared.open(ContentURLs.shared.statusInfo)
    }

    @IBAction func adviceTapped() {
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

    @IBAction func unwindFromUnexposed(unwindSegue: UIStoryboardSegue) {
        statusStateMachine.ok()
    }

    @IBAction func unwindFromDrawer(unwindSegue: UIStoryboardSegue) {
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
        case .ok, .unexposed:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
            diagnosisTitleLabel.text = "Follow the current advice to stop the spread of coronavirus"
            diagnosisDetailLabel.isHidden = true
            feelUnwellButton.isHidden = false
            applyForTestButton.isHidden = true
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "If you don’t have any symptoms, there’s no need to do anything right now. If you develop symptoms, please come back to this app."

            if case .unexposed = statusStateMachine.state {
                let config = DrawerViewController.Config(
                    header: "UNEXPOSED_DRAWER_HEADER".localized,
                    detail: "UNEXPOSED_DRAWER_DETAIL".localized
                )
                performSegue(withIdentifier: "presentDrawer", sender: config)
            }

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
            detailForSymptomatic(state: symptomatic)
            
        case .unclearTestResult(let unclearTestResult):
            // Use symptomatic detail as it's the same visually
            detailForSymptomatic(state: unclearTestResult)
            presentTestResultUpdate(result: .unclear)

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
            
        case .positiveTestResult(let positiveTestResult):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "Your test result indicates  you  have coronavirus. Please isolate yourself and your household."
            diagnosisDetailLabel.isHidden = false
            diagnosisDetailLabel.text = userStatusProvider.detailWithExpiryDate(positiveTestResult.expiryDate)
            feelUnwellButton.isHidden = true
            applyForTestButton.isHidden = true
            nextStepsDetailView.isHidden = true
        }
        
    }
    
    func detailForSymptomatic(state: Expirable) {
        diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
        diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."
        diagnosisDetailLabel.isHidden = false
        diagnosisDetailLabel.text = userStatusProvider.detailWithExpiryDate(state.expiryDate)
        feelUnwellButton.isHidden = true
        applyForTestButton.isHidden = false
        stepsDetailLabel.isHidden = false
        stepsDetailLabel.text = "Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"

    }

    private func presentCoughUpdate() {
        let config = DrawerViewController.Config(
            header: "COUGH_UPDATE_HEADER".localized,
            detail: "COUGH_UPDATE_DETAIL".localized
        )
        performSegue(withIdentifier: "presentDrawer", sender: config)
    }
    
    private func presentTestResultUpdate(result: TestResult.Result) {
        let header = result.headerText
        let detail = result.detailText
        let config = DrawerViewController.Config(header: header, detail: detail)
        performSegue(withIdentifier: "presentDrawer", sender: config)
    }

}

private let logger = Logger(label: "StatusViewController")

class TouchCancellingScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}
