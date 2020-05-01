//
//  AppDelegate.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseInstanceID
import Logging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    let notificationCenter = NotificationCenter.default
    let userNotificationCenter = UNUserNotificationCenter.current()
    let authorizationManager = AuthorizationManager()
    
    #warning("Replace with a `PublicKeyValidator` configured from the environment.")
    let trustValidator = DefaultTrustValidating()
    
    lazy var monitor: AppMonitoring = AppCenterMonitor.shared
    
    lazy var urlSession: Session = URLSession(trustValidator: trustValidator)

    lazy var dispatcher: RemoteNotificationDispatching = RemoteNotificationDispatcher(
        notificationCenter: notificationCenter,
        userNotificationCenter: userNotificationCenter)

    lazy var remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager(
        firebase: FirebaseApp.self,
        messagingFactory: { Messaging.messaging() },
        userNotificationCenter: userNotificationCenter,
        notificationAcknowledger: notificationAcknowledger,
        dispatcher: dispatcher)
    
    lazy var registrationService: RegistrationService = ConcreteRegistrationService(
        session: urlSession,
        persistence: persistence,
        reminderScheduler: ConcreteRegistrationReminderScheduler(userNotificationCenter: userNotificationCenter),
        remoteNotificationDispatcher: dispatcher,
        notificationCenter: notificationCenter,
        monitor: monitor,
        timeoutQueue: DispatchQueue.main)

    lazy var persistence: Persisting = Persistence(
        secureRegistrationStorage: SecureRegistrationStorage(),
        broadcastKeyStorage: SecureBroadcastRotationKeyStorage(),
        monitor: monitor
    )

    lazy var bluetoothNursery: BluetoothNursery = ConcreteBluetoothNursery(persistence: persistence, userNotificationCenter: userNotificationCenter, notificationCenter: notificationCenter, monitor: monitor)
    
    lazy var onboardingCoordinator: OnboardingCoordinating = OnboardingCoordinator(
        persistence: persistence,
        authorizationManager: authorizationManager,
        bluetoothNursery: bluetoothNursery
    )
    
    lazy var contactEventsUploader: ContactEventsUploader = ContactEventsUploader(
        persisting: persistence,
        contactEventRepository: bluetoothNursery.contactEventRepository,
        trustValidator: trustValidator,
        makeSession: makeBackgroundSession
    )

    lazy var makeBackgroundSession: (String, URLSessionDelegate) -> Session = { id, delegate in
        let config = URLSessionConfiguration.background(withIdentifier: id)
        config.secure()
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    lazy var linkingIdManager: LinkingIdManager = LinkingIdManager(
        notificationCenter: notificationCenter,
        persisting: persistence,
        session: urlSession
    )

    lazy var statusProvider: StatusProvider = StatusProvider(
        persisting: persistence
    )

    lazy var statusNotificationHandler: StatusNotificationHandler = StatusNotificationHandler(
        persisting: persistence,
        userNotificationCenter: userNotificationCenter,
        notificationCenter: notificationCenter
    )

    lazy var notificationAcknowledger: NotificationAcknowledger = NotificationAcknowledger(
        persisting: persistence,
        session: urlSession
    )

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        if let window = UITestResponder.makeWindowForTesting() {
            self.window = window
            return true
        }
        #endif

        LoggingManager.bootstrap()
        logger.info("Launched", metadata: Logger.Metadata(launchOptions: launchOptions))

        application.registerForRemoteNotifications()

        remoteNotificationManager.configure()
        dispatcher.registerHandler(forType: .status) { userInfo, completion in
            self.statusNotificationHandler.handle(userInfo: userInfo, completion: completion)
        }

        Appearance.setup()
        
        writeBuildInfo()

        let rootVC = RootViewController()
        rootVC.inject(
            persistence: persistence,
            authorizationManager: authorizationManager,
            remoteNotificationManager: remoteNotificationManager,
            notificationCenter: notificationCenter,
            registrationService: registrationService,
            bluetoothNursery: bluetoothNursery,
            onboardingCoordinator: onboardingCoordinator,
            monitor: monitor,
            session: urlSession,
            contactEventsUploader: contactEventsUploader,
            linkingIdManager: linkingIdManager,
            statusProvider: statusProvider,
            uiQueue: DispatchQueue.main
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        
        // Check registration as well as bluetoothPermissionRequested, because the user may have registered
        // on an old version of the app that didn't record bluetoothPermissionRequested.
        if persistence.bluetoothPermissionRequested || persistence.registration != nil {
            bluetoothNursery.startBluetooth(registration: persistence.registration)
        }

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.info("Received notification", metadata: Logger.Metadata(dictionary: userInfo))
        
        remoteNotificationManager.handleNotification(userInfo: userInfo, completionHandler: { result in
             completionHandler(result)
        })
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        logger.info("Terminating")

        scheduleLocalNotification()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        logger.info("Will Resign Active")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.info("Did Become Active")

        try? contactEventsUploader.ensureUploading()
        linkingIdManager.fetchLinkingId()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.info("Did Enter Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.info("Will Enter Foreground")
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        // https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622941-application
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background

        // This is called even if the app is in the background or suspended and a background
        // URLSession task finishes. We're supposed to reconstruct the background session and
        // attach a delegate to it when this gets called, but we already do that as part of
        // the app launch, so can skip that here. However, we do need to attach the completion
        // handler to the delegate so that we can notify the system when we're done processing
        // the task events.

        contactEventsUploader.sessionDelegate.completionHandler = completionHandler
    }

    // MARK: - Private
    
    private func scheduleLocalNotification() {
        let scheduler = HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)

        scheduler.scheduleLocalNotification(
            title: nil,
            body: "To keep yourself secure, please relaunch the app.",
            interval: 10,
            identifier: "willTerminate.relaunch.please",
            repeats: false
        )
    }
    
    private func writeBuildInfo() {
        persistence.lastInstalledBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        persistence.lastInstalledVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - Logging
private let logger = Logger(label: "Application")
