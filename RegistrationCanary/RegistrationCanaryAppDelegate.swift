//
//  AppDelegate.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/9/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

@UIApplicationMain
class RegistrationCanaryAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private lazy var remoteNotificationDispatcher = RemoteNotificationDispatcher(
        notificationCenter: NotificationCenter.default,
        userNotificationCenter: UNUserNotificationCenter.current()
    )
    private lazy var persistence = InMemoryRegistrationPersistence()
    private let trustValidator = PublicKeyValidator(trustedKeyHashes: ["hETpgVvaLC0bvcGG3t0cuqiHvr4XyP2MTwCiqhgRWwU="])
    private lazy var urlSession = URLSession(trustValidator: trustValidator)
    private lazy var notificationAcknowledger = NotificationAcknowledger(persisting: persistence, session: urlSession)
    private lazy var remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager(
        firebase: FirebaseApp.self,
        messagingFactory: { Messaging.messaging() },
        userNotificationCenter: UNUserNotificationCenter.current(),
        notificationAcknowledger: notificationAcknowledger,
        dispatcher: remoteNotificationDispatcher
    )
    private lazy var registrationService = ConcreteRegistrationService(
        session: urlSession,
        persistence: InMemoryRegistrationPersistence(),
        reminderScheduler: NoOpRegistrationReminderScheduler(),
        remoteNotificationDispatcher: remoteNotificationDispatcher,
        notificationCenter: NotificationCenter.default,
        monitor: NoOpAppMonitoring(),
        timeoutQueue: DispatchQueue.main
    )

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        LoggingManager.bootstrap()
        logger.info("Launched")

        remoteNotificationManager.configure()
        let vc = ViewController.instantiate()
        vc.inject(registrationService: registrationService)
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = vc
        window!.makeKeyAndVisible()

        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.info("Received notification", metadata: Logger.Metadata(dictionary: userInfo))
        
        remoteNotificationManager.handleNotification(userInfo: userInfo, completionHandler: { result in
             completionHandler(result)
        })
    }
}

private let logger = Logger(label: "AppDelegate")
