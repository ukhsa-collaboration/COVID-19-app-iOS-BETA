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
    let urlSession = URLSession.make()
    let authorizationManager = AuthorizationManager()

    lazy var dispatcher: RemoteNotificationDispatching = RemoteNotificationDispatcher(
        notificationCenter: notificationCenter,
        userNotificationCenter: userNotificationCenter)

    lazy var remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager(
        firebase: FirebaseApp.self,
        messagingFactory: { Messaging.messaging() },
        userNotificationCenter: userNotificationCenter,
        dispatcher: dispatcher)
    
    lazy var registrationService: RegistrationService = ConcreteRegistrationService(
        session: urlSession,
        persistence: persistence,
        remoteNotificationDispatcher: dispatcher,
        notificationCenter: notificationCenter,
        timeoutQueue: DispatchQueue.main)

    lazy var persistence: Persisting = Persistence.shared

    lazy var bluetoothNursery: BluetoothNursery = ConcreteBluetoothNursery(persistence: persistence, userNotificationCenter: userNotificationCenter, notificationCenter: notificationCenter)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO: If DEBUG is only necessary as long as we have the same bundle ID for both builds.
        #if INTERNAL || DEBUG
        if let window = UITestResponder.makeWindowForTesting() {
            self.window = window
            return true
        }
        #endif

        LoggingManager.bootstrap()
        logger.info("Launched", metadata: Logger.Metadata(launchOptions: launchOptions))

        persistence.delegate = self
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
            bluetoothNursery: bluetoothNursery,
            bluetoothStateObserver: ConcreteBluetoothStateObserver(),
            session: urlSession,
            uiQueue: DispatchQueue.main
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        if let registration = persistence.registration {
            bluetoothNursery.startListener(stateDelegate: nil)
            bluetoothNursery.startBroadcaster(stateDelegate: nil)
//            bluetoothNursery.startBroadcastingAndListening(registration: registration)
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
//        bluetoothNursery.startBroadcastingAndListening(registration: registration)
    }
}

// MARK: - Logging
private let logger = Logger(label: "Application")
