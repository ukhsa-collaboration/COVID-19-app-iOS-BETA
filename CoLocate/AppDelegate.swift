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
    let registrationService = ConcreteRegistrationService()
    let bluetoothNursery = BluetoothNursery()
    let authorizationManager = AuthorizationManager()

    var appCoordinator: AppCoordinator!

    override init() {
        LoggingManager.bootstrap()
        
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

        let rootVC = RootViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        if let registration = persistence.registration {
            bluetoothNursery.startBroadcaster(stateDelegate: nil)
            bluetoothNursery.broadcaster?.sonarId = registration.id
            bluetoothNursery.startListener(stateDelegate: BluetoothStateObserver.shared)
            startMainApp()
        } else {
            let onboardingViewController = OnboardingViewController.instantiate()
            let env = OnboardingEnvironment(persistence: persistence, authorizationManager: authorizationManager, remoteNotificationManager: remoteNotificationManager)
            let coordinator = OnboardingCoordinator(persistence: persistence, authorizationManager: authorizationManager)
            
            onboardingViewController.inject(env: env, coordinator: coordinator) {
                self.startMainApp()
            }
            
            onboardingViewController.showIn(rootViewController: rootVC)
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

        flushContactEvents()
        scheduleLocalNotification()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        logger.info("Will Resign Active")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.info("Did Become Active")

        guard self.persistence.registration != nil else {
            // TODO : is this true ? What about the last onboarding screen ?
            logger.debug("Became active with nil registration. Assuming onboarding will handle this case")
            return
        }

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            DispatchQueue.main.sync {
                guard let rootViewController = self.window?.rootViewController as? RootViewController else {
                    return
                }

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
    
    func startMainApp() {
        guard let rootViewController = window?.rootViewController as? RootViewController else {
            return
        }

        appCoordinator = AppCoordinator(
            rootViewController: rootViewController,
            persistence: persistence,
            registrationService: registrationService
        )
        appCoordinator.update()
    }

    func flushContactEvents() {
        bluetoothNursery.contactEventCollector.flush()
    }

    func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.body = "To keep yourself secure, please relaunch the app."

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "willTerminate.relaunch.please", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - PersistenceDelegate

extension AppDelegate: PersistenceDelegate {
    func persistence(_ persistence: Persistence, didRecordDiagnosis diagnosis: Diagnosis) {
        appCoordinator.update()
    }

    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        bluetoothNursery.broadcaster?.sonarId = registration.id
        bluetoothNursery.startListener(stateDelegate: BluetoothStateObserver.shared)
    }
}

// MARK: - Logging
private let logger = Logger(label: "Application")
