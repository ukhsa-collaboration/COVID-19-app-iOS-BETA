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
    
    var animateTransitions = true

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
    private var drawerPresenter: DrawerPresenter!
    private var drawerMailbox: DrawerMailboxing!
    private var localeProvider: LocaleProvider!
    
    func inject(
        statusStateMachine: StatusStateMachining,
        userStatusProvider: UserStatusProvider,
        persistence: Persisting,
        linkingIdManager: LinkingIdManaging,
        registrationService: RegistrationService,
        dateProvider: @escaping () -> Date = { Date() },
        notificationCenter: NotificationCenter,
        drawerPresenter: DrawerPresenter = ConcreteDrawerPresenter(),
        drawerMailbox: DrawerMailboxing,
        localeProvider: LocaleProvider
    ) {
        self.linkingIdManager = linkingIdManager
        self.statusStateMachine = statusStateMachine
        self.userStatusProvider = userStatusProvider
        self.persistence = persistence
        self.registrationService = registrationService
        self.dateProvider = dateProvider
        self.notificationCenter = notificationCenter
        self.drawerPresenter = drawerPresenter
        self.drawerMailbox = drawerMailbox
        self.localeProvider = localeProvider
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
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Info"

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
        notificationCenter.addObserver(self, selector: #selector(reload), name: StatusStateMachine.StatusStateChangedNotification, object: nil)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reload()
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        super.present(viewControllerToPresent, animated: animated && animateTransitions, completion: completion)
    }

    @objc func infoTapped() {
        UIApplication.shared.open(ContentURLs.shared.statusInfo)
    }

    @IBAction func adviceTapped() {
        let adviceVc = AdviceViewController.instantiate()
        adviceVc.inject(state: statusStateMachine.state, localeProvider: localeProvider)
        navigationController?.pushViewController(adviceVc, animated: animateTransitions)
    }

    @IBAction func feelUnwellTapped(_ sender: Any) {
        let coordinator = SelfDiagnosisCoordinator(
            navigationController: navigationController!,
            statusStateMachine: statusStateMachine
        ) { symptoms in
            self.navigationController?.popToViewController(self, animated: self.animateTransitions)

            if symptoms.contains(.cough), case .ok = self.statusStateMachine.state {
                self.presentHaveSymptomsButDontIsolateUpdate()
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
        navigationController?.pushViewController(linkingIdVc, animated: animateTransitions)
    }

    @IBAction func workplaceGuidanceTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showWorkplaceGuidance", sender: self)
    }

    @IBAction func unwindFromDrawer(unwindSegue: UIStoryboardSegue) {
    }
    
    func presentNegativePrompt(symptoms: Symptoms) {
        let symptomsPromptViewController = SymptomsPromptViewController.instantiate()
        
        if animateTransitions {
            symptomsPromptViewController.modalPresentationStyle = .custom
            symptomsPromptViewController.transitioningDelegate = drawerPresentationManager
        }
        symptomsPromptViewController.inject(headerText: "NEGATIVE_RESULT_QUESTIONNAIRE_OVERLAY_HEADER".localized,
                                            detailText: "NEGATIVE_RESULT_QUESTIONNAIRE_OVERLAY_DETAIL".localized) { needsCheckin in
            self.dismiss(animated: self.animateTransitions)

            if needsCheckin {
                CheckinCoordinator(navigationController: self.navigationController!, previousSymptoms: symptoms) { symptoms in
                    if symptoms.contains(.temperature) {
                        self.statusStateMachine.set(state: self.statusStateMachine.state.resolved())
                    } else {
                        self.statusStateMachine.set(state: .ok(StatusState.Ok()))
                    }
                    self.navigationController!.popToRootViewController(animated: self.animateTransitions)
                }.start()
            } else {
                self.statusStateMachine.set(state: .ok(StatusState.Ok()))
            }
        }
        present(symptomsPromptViewController, animated: animateTransitions)
    }

    fileprivate func presentCheckinPrompt(for symptoms: Symptoms?) {
        let symptomsPromptViewController = SymptomsPromptViewController.instantiate()
        
        if animateTransitions {
            symptomsPromptViewController.modalPresentationStyle = .custom
            symptomsPromptViewController.transitioningDelegate = drawerPresentationManager
        }
        
        symptomsPromptViewController.inject(headerText: "CHECKIN_QUESTIONNAIRE_OVERLAY_HEADER".localized,
                                            detailText: "CHECKIN_QUESTIONNAIRE_OVERLAY_DETAIL".localized) { needsCheckin in
            self.dismiss(animated: self.animateTransitions)

            if needsCheckin {
                let coordinator = CheckinCoordinator(
                    navigationController: self.navigationController!,
                    previousSymptoms: symptoms
                ) { symptoms in
                    self.statusStateMachine.checkin(symptoms: symptoms)
                        
                    self.navigationController!.popToRootViewController(animated: self.animateTransitions)

                    if symptoms.any(), case .ok = self.statusStateMachine.state {
                        self.presentHaveSymptomsButDontIsolateUpdate()
                    }
                }
                coordinator.start()
            } else {
                self.statusStateMachine.checkin(symptoms: [])
            }
        }
        present(symptomsPromptViewController, animated: animateTransitions)
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
        
        present(alertController, animated: animateTransitions, completion: nil)
    }
    
    @objc func reload() {
        statusStateMachine.tick()
        setupUI(for: statusStateMachine.state)
        showDrawer()
    }
    
    func setupUI(for state: StatusState) {
        guard view != nil else { return }
        
        switch state {
        case .ok, .unexposed:
            detailForNeutral()

        case .negativeTestResult(let nextState):
            if nextState != state {
                setupUI(for: nextState)
            }
            if case .ok = nextState {
                presentTestResultUpdate(result: .negative)
            } else {
                presentNegativePrompt(symptoms: nextState.symptoms ?? [])
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
            detailForSelfIsolation(expiryDate: symptomatic.checkinDate)

            if dateProvider() >= symptomatic.checkinDate {
                presentCheckinPrompt(for: symptomatic.symptoms)
            }

        case .unclearTestResult(let unclear):
            // Use symptomatic detail as it's the same visually
            detailForSelfIsolation(expiryDate: unclear.expiryDate)

            presentTestResultUpdate(result: .unclear)

        case .positiveTestResult(let positiveTestResult):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "Your test result indicates  you  have coronavirus. Please isolate yourself and your household."
            diagnosisDetailLabel.isHidden = false
            diagnosisDetailLabel.text = userStatusProvider.detailWithExpiryDate(positiveTestResult.expiryDate)
            feelUnwellButton.isHidden = true
            applyForTestButton.isHidden = true
            nextStepsDetailView.isHidden = true
            
            presentTestResultUpdate(result: .positive)
        }
    }

    private func showDrawer() {
        guard let message = drawerMailbox.receive() else { return }

        switch message {
        case .unexposed:
            let config = DrawerViewController.Config(
                header: "UNEXPOSED_DRAWER_HEADER".localized,
                detail: "UNEXPOSED_DRAWER_DETAIL".localized
            ) {
                self.reload()
            }
            presentDrawer(with: config)
        case .symptomsButNotSymptomatic:
            assertionFailure("TODO")
        case .testResult(.positive):
            assertionFailure("TODO")
        case .testResult(.negative):
            assertionFailure("TODO")
        case .testResult(.unclear):
            assertionFailure("TODO")
        }
    }

    func detailForSelfIsolation(expiryDate: Date) {
        diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
        diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."
        diagnosisDetailLabel.isHidden = false
        diagnosisDetailLabel.text = userStatusProvider.detailWithExpiryDate(expiryDate)
        feelUnwellButton.isHidden = true
        applyForTestButton.isHidden = false
        stepsDetailLabel.isHidden = false
        stepsDetailLabel.text = "Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"
    }
    
    func detailForNeutral() {
        diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
        diagnosisTitleLabel.text = "Follow the current advice to stop the spread of coronavirus"
        diagnosisDetailLabel.isHidden = true
        feelUnwellButton.isHidden = false
        applyForTestButton.isHidden = true
        stepsDetailLabel.isHidden = false
        stepsDetailLabel.text = "If you don’t have any symptoms, there’s no need to do anything right now. If you develop symptoms, please come back to this app."
    }

    private func presentHaveSymptomsButDontIsolateUpdate() {
        let config = DrawerViewController.Config(
            header: "HAVE_SYMPTOMS_BUT_DONT_ISOLATE_DRAWER_HEADER".localized,
            detail: "HAVE_SYMPTOMS_BUT_DONT_ISOLATE_DRAWER_DETAIL".localized
        )
        presentDrawer(with: config)
    }
    
    private func presentTestResultUpdate(result: TestResult.ResultType) {
        let header = result.headerText
        let detail = result.detailText
        let config = DrawerViewController.Config(header: header, detail: detail) { [weak self] in
            self?.statusStateMachine.clearInterstitialState()
        }
        
        performSegue(withIdentifier: "presentDrawer", sender: config)
    }
        
    private func presentDrawer(with config: DrawerViewController.Config) {
        let drawer = DrawerViewController.instantiate() { $0.inject(config: config) }
        drawerPresenter.present(
            drawer: drawer,
            inNavigationController: navigationController!,
            usingTransitioningDelegate: drawerPresentationManager
        )
    }
}

protocol DrawerPresenter {
    func present(
        drawer: DrawerViewController,
        inNavigationController: UINavigationController,
        usingTransitioningDelegate: UIViewControllerTransitioningDelegate
    )
}

class ConcreteDrawerPresenter: DrawerPresenter {
    func present(
        drawer: DrawerViewController,
        inNavigationController navigationController: UINavigationController,
        usingTransitioningDelegate delegate: UIViewControllerTransitioningDelegate
    ) {
        drawer.modalPresentationStyle = .custom
        drawer.transitioningDelegate = delegate
        
        navigationController.visibleViewController!.present(drawer, animated: true)
    }
}

private let logger = Logger(label: "StatusViewController")

class TouchCancellingScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}
