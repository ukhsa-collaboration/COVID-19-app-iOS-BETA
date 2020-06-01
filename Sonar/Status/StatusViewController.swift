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

    @IBOutlet weak var nextStepsDetailView: UIStackView!

    @IBOutlet weak var feelUnwellButton: UIButton!
    @IBOutlet weak var feelUnwellTitleLabel: UILabel!
    @IBOutlet weak var feelUnwellBodyLabel: UILabel!

    @IBOutlet weak var bookTestButton: UIButton!
    @IBOutlet weak var bookTestLabel: UILabel!
    @IBOutlet weak var stepsDetailLabel: UILabel!
    @IBOutlet weak var medicalEmergencyLabel: UILabel!
    @IBOutlet weak var nhsServicesStackView: UIStackView!
    @IBOutlet weak var nhsCoronavirusLinkButton: LinkButton!
    @IBOutlet var sectionHeaders: [UILabel]!
    
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
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Link to more information about NHS COVID-19 app"

        diagnosisHighlightView.layer.cornerRadius = diagnosisHighlightView.bounds.width / 2
        diagnosisHighlightView.accessibilityIgnoresInvertColors = true

        setupBannerAppearance(hasNotificationProblem: hasNotificationProblem,
                              bannerDisabled: persistence.disabledNotificationsStatusView)
                
        goToSettingsButton.titleLabel?.text = "GO_TO_SETTINGS".localized
        disableNotificationStatusViewButton.titleLabel?.text = "DISABLE_NOTIFICATIONS_STATUS_VIEW".localized

        feelUnwellButton.accessibilityLabel = [
            feelUnwellTitleLabel.text, feelUnwellBodyLabel.text
        ].compactMap { $0 }.joined(separator: ". ")
        bookTestButton.accessibilityLabel = bookTestLabel.text

        diagnosisStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.setCustomSpacing(32, after: diagnosisStackView)
        contentStackView.setCustomSpacing(32, after: nextStepsDetailView)
        nhsServicesStackView.isLayoutMarginsRelativeArrangement = true

        nhsCoronavirusLinkButton.url = ContentURLs.shared.regionalServices

        (sectionHeaders + [stepsDetailLabel, feelUnwellBodyLabel, medicalEmergencyLabel]).forEach {
            $0.textColor = UIColor(named: "NHS Secondary Text")
        }
        medicalEmergencyLabel.text = "STATUS_GET_HELP".localized
        
        notificationCenter.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(reload), name: StatusStateMachine.StatusStateChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(showDrawer), name: DrawerMessage.DrawerMessagePosted, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as RegistrationStatusViewController:
            vc.inject(persistence: persistence, registrationService: registrationService, notificationCenter: notificationCenter)
        case let vc as BookTestContainerViewController:
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: DispatchQueue.main)
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
        let coordinator = QuestionnaireCoordinator(
            navigationController: navigationController!,
            statusStateMachine: statusStateMachine,
            questionnaireType: .selfDiagnosis
        ) { symptoms in
            self.navigationController?.popToViewController(self, animated: self.animateTransitions)
        }

        coordinator.start()
    }

    @IBAction func bookTestTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showBookTest", sender: self)
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

    fileprivate func presentCheckinDrawer(for symptoms: Symptoms?, header: String, detail: String) {
        let checkinDrawer = CheckinDrawerViewController.instantiate()
        
        if animateTransitions {
            checkinDrawer.modalPresentationStyle = .custom
            checkinDrawer.transitioningDelegate = drawerPresentationManager
        }
        
        checkinDrawer.inject(headerText: header, detailText: detail) { needsCheckin in
            self.dismiss(animated: self.animateTransitions)

            if needsCheckin {
                let coordinator = QuestionnaireCoordinator(
                    navigationController: self.navigationController!,
                    statusStateMachine: self.statusStateMachine,
                    questionnaireType: .checkin
                ) { symptoms in
                    self.statusStateMachine.checkin(symptoms: symptoms)
                        
                    self.navigationController!.popToRootViewController(animated: self.animateTransitions)
                }
                coordinator.start()
            } else {
                self.statusStateMachine.checkin(symptoms: [])
            }
        }
        present(checkinDrawer, animated: animateTransitions)
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
        case .ok:
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Blue")
            diagnosisTitleLabel.text = "Follow the current advice to stop the spread of coronavirus"
            diagnosisDetailLabel.isHidden = true
            feelUnwellButton.isHidden = false
            bookTestButton.isHidden = true
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "STATUS_GET_HELP_OK".localized + "\n"

        case .exposed(let exposed):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "You have been near someone who has tested positive for coronavirus. Please self-isolate."
            diagnosisDetailLabel.text = "Please isolate until \(localizedDate(exposed.expiryDate)). Please read your full advice below."
            diagnosisDetailLabel.isHidden = false
            feelUnwellButton.isHidden = false
            bookTestButton.isHidden = true
            stepsDetailLabel.isHidden = false
            stepsDetailLabel.text = "STATUS_GET_HELP_EXPOSED".localized + "\n"

        case .symptomatic(let symptomatic):
            setupDetail(for: symptomatic)
            
        case .exposedSymptomatic(let exposedSymptomatic):
            setupDetail(for: exposedSymptomatic)

        case .positiveTestResult(let positiveTestResult):
            diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
            diagnosisTitleLabel.text = "Your test result indicates you have coronavirus. Please isolate yourself and your household."
            diagnosisDetailLabel.isHidden = false
            diagnosisDetailLabel.text = pleaseIsolateText(until: positiveTestResult.checkinDate)
            feelUnwellButton.isHidden = true
            bookTestButton.isHidden = true
            stepsDetailLabel.isHidden = true
            
            if dateProvider() >= positiveTestResult.checkinDate {
                presentCheckinDrawer(
                    for: positiveTestResult.symptoms,
                    header: "CHECKIN_QUESTIONNAIRE_OVERLAY_HEADER".localized,
                    detail: "CHECKIN_QUESTIONNAIRE_OVERLAY_DETAIL".localized
                )
            }
        }
    }
    
    func setupDetail<T>(for state: T) where T: SymptomProvider & Checkinable {
        diagnosisHighlightView.backgroundColor = UIColor(named: "NHS Warm Yellow")
        diagnosisTitleLabel.text = "Your symptoms indicate you may have coronavirus. Please isolate yourself and your household and book a test."
        diagnosisDetailLabel.isHidden = false
        diagnosisDetailLabel.text = pleaseIsolateText(until: state.checkinDate)
        feelUnwellButton.isHidden = true
        bookTestButton.isHidden = false
        stepsDetailLabel.isHidden = true

        if dateProvider() >= state.checkinDate {
            presentCheckinDrawer(
                for: state.symptoms,
                header: "CHECKIN_QUESTIONNAIRE_OVERLAY_HEADER".localized,
                detail: "CHECKIN_QUESTIONNAIRE_OVERLAY_DETAIL".localized
            )
        }
    }

    @objc private func showDrawer() {
        guard let message = drawerMailbox.receive() else { return }

        switch message {
        case .unexposed:
            presentDrawer(
                header: "UNEXPOSED_DRAWER_HEADER".localized,
                detail: "UNEXPOSED_DRAWER_DETAIL".localized
            )
        case .symptomsButNotSymptomatic:
            presentDrawer(
                header: "HAVE_SYMPTOMS_BUT_DONT_ISOLATE_DRAWER_HEADER".localized,
                detail: "HAVE_SYMPTOMS_BUT_DONT_ISOLATE_DRAWER_DETAIL".localized
            )
        case .positiveTestResult:
            presentDrawer(
                header: "TEST_UPDATE_DRAW_POSITIVE_HEADER".localized,
                detail: "TEST_UPDATE_DRAW_POSITIVE_DETAIL".localized
            )
        case .negativeTestResult(let symptoms):
            if let symptoms = symptoms {
                presentCheckinDrawer(
                    for: symptoms,
                    header: "NEGATIVE_RESULT_QUESTIONNAIRE_OVERLAY_HEADER".localized,
                    detail: "NEGATIVE_RESULT_QUESTIONNAIRE_OVERLAY_DETAIL".localized
                )
            } else {
                presentDrawer(
                    header: "TEST_UPDATE_DRAW_NEGATIVE_HEADER".localized,
                    detail: "TEST_UPDATE_DRAW_NEGATIVE_DETAIL".localized
                )
            }
        case .unclearTestResult:
            presentDrawer(
                header: "TEST_UPDATE_DRAW_INVALID_HEADER".localized,
                detail: "TEST_UPDATE_DRAW_INVALID_DETAIL".localized
            )
        }
    }

    private func presentDrawer(header: String, detail: String) {
        let drawer = DrawerViewController.instantiate()
        drawer.inject(header: header, detail: detail) { self.showDrawer() }
        drawerPresenter.present(
            drawer: drawer,
            inNavigationController: navigationController!,
            usingTransitioningDelegate: drawerPresentationManager
        )
    }

    private func pleaseIsolateText(until expiryDate: Date) -> String {
        let detailFmt = "Please isolate until %@ when this app will notify you to update your symptoms. Please read your full advice below.".localized
        return String(format: detailFmt, localizedDate(expiryDate))
    }

    private func localizedDate(_ date: Date, _ template: String = "MMMMd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = localeProvider.locale
        dateFormatter.setLocalizedDateFormatFromTemplate(template)
        return dateFormatter.string(from: date)
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
