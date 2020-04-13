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

    let remoteNotificationManager = ConcreteRemoteNotificationManager.shared
    let persistence = Persistence.shared
    let bluetoothNursery = BluetoothNursery()
    let authorizationManager = AuthorizationManager()

    var appCoordinator: AppCoordinator!

    override init() {
        LoggingManager.bootstrap()
        
        super.init()

        persistence.delegate = self
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO (TJ): temporarily reset contact events upon startup
        // Justification : we are NOT migrating our storage right now
        // since we don't anticipate needing to until after launch
        // but since I have JUST migrated the format of these records
        // if we don't do this, the app crashes upon startup
        // so I'm doing this so that everyone's unit tests and apps continue to work
        PersistingContactEventRepository.shared.reset()
        PlistPersister<ContactEvent>(fileName: "contactEvents").reset()

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
            notificationCenter: NotificationCenter.default,
            registrationService: ConcreteRegistrationService()
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

        guard self.persistence.registration != nil else { return }

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            DispatchQueue.main.sync {
                guard let rootViewController = self.window?.rootViewController as? RootViewController else { return }

                switch (self.authorizationManager.bluetooth, notificationStatus) {
                case (.denied, _), (_, .denied):
                    let permissionsDeniedViewController = PermissionsDeniedViewController.instantiate()
                    rootViewController.present(permissionsDeniedViewController, animated: true)
                default:
                    guard rootViewController.presentedViewController as? PermissionsDeniedViewController != nil else {
                        return
                    }

                    rootViewController.dismiss(animated: true)
                }
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.info("Did Enter Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.info("Will Enter Foreground")
    }

    // MARK: - Private
    
    func scheduleLocalNotification() {
        let scheduler = HumbleLocalNotificationScheduler.shared

        scheduler.scheduleLocalNotification(
            body: "To keep yourself secure, please relaunch the app.",
            interval: 10,
            identifier: "willTerminate.relaunch.please"
        )
    }
}

// MARK: - PersistenceDelegate

extension AppDelegate: PersistenceDelegate {
    func persistence(_ persistence: Persistence, didRecordDiagnosis diagnosis: Diagnosis) {
        appCoordinator.update()
    }

    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        bluetoothNursery.startBroadcastingAndListening(registration: registration)
    }
}

// MARK: - Logging
private let logger = Logger(label: "Application")
