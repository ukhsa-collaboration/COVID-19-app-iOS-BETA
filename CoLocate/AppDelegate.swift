//
//  AppDelegate.swift
//  CoLocate
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
    let persistence = Persistence.shared
    let authorizationManager = AuthorizationManager()
    let bluetoothNursery: BluetoothNursery
    let remoteNotificationManager: RemoteNotificationManager
    let registrationService: RegistrationService

    override init() {
        LoggingManager.bootstrap()
        
        let dispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: userNotificationCenter
        )
        remoteNotificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseApp.self,
            messagingFactory: { Messaging.messaging() },
            userNotificationCenter: userNotificationCenter,
            dispatcher: dispatcher
        )
        registrationService = ConcreteRegistrationService(
            session: URLSession.shared,
            persistence: persistence,
            remoteNotificationDispatcher: dispatcher,
            notificationCenter: notificationCenter
        )
        bluetoothNursery = BluetoothNursery(persistence: persistence, userNotificationCenter: userNotificationCenter, notificationCenter: notificationCenter)
        
        
        super.init()

        persistence.delegate = self
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO: If DEBUG is only necessary as long as we have the same bundle ID for both builds.
        #if INTERNAL || DEBUG
        if let window = UITestResponder.makeWindowForTesting() {
            self.window = window
            return true
        }
        #endif
        
        logger.info("Launched", metadata: Logger.Metadata(launchOptions: launchOptions))
        
        application.registerForRemoteNotifications()

        remoteNotificationManager.configure()

        Appearance.setup()

        let rootVC = RootViewController()
        rootVC.inject(
            persistence: persistence,
            authorizationManager: authorizationManager,
            remoteNotificationManager: remoteNotificationManager,
            notificationCenter: notificationCenter,
            registrationService: registrationService,
            contactEventRepository: bluetoothNursery.contactEventRepository,
            session: URLSession.shared,
            uiQueue: DispatchQueue.main
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        if let registration = persistence.registration {
            bluetoothNursery.startBroadcastingAndListening(registration: registration)
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
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.info("Did Enter Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.info("Will Enter Foreground")
    }

    // MARK: - Private
    
    func scheduleLocalNotification() {
        let scheduler = HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)

        scheduler.scheduleLocalNotification(
            body: "To keep yourself secure, please relaunch the app.",
            interval: 10,
            identifier: "willTerminate.relaunch.please"
        )
    }
}

// MARK: - PersistenceDelegate

extension AppDelegate: PersistenceDelegate {
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        bluetoothNursery.startBroadcastingAndListening(registration: registration)
    }
}

// MARK: - Logging
private let logger = Logger(label: "Application")
