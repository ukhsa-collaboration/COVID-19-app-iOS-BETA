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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    let broadcaster: BTLEBroadcaster
    let listener: BTLEListener

    let notificationManager: NotificationManager = ConcreteNotificationManager()
    let persistance = Persistance.shared
    let registrationService: RegistrationService

    var appCoordinator: AppCoordinator!
    
    override init() {
        LoggingManager.bootstrap()
        
        broadcaster = BTLEBroadcaster()
        listener = BTLEListener()
        
        registrationService = ConcreteRegistrationService(session: URLSession.shared, notificationManager: notificationManager, notificationCenter: NotificationCenter.default)

        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        application.registerForRemoteNotifications()

        notificationManager.configure()

        let rootViewController = RootViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController

        if !persistance.newOnboarding {
            if let registration = persistance.registration {
                continueWithRegistration(registration)
            } else {
                let registrationCoordinator = RegistrationCoordinator(navController: rootViewController,
                                                                      notificationManager: notificationManager,
                                                                      registrationService: registrationService,
                                                                      persistance: persistance,
                                                                      notificationCenter: NotificationCenter.default)
                NotificationCenter.default.addObserver(self, selector: #selector(didCompleteRegistration(notification:)), name: RegistrationCompleteNotification, object: nil)
                registrationCoordinator.start()
            }
        }

        window?.makeKeyAndVisible()

        if persistance.newOnboarding {
            let onboardingViewController = OnboardingViewController.instantiate()
            onboardingViewController.rootViewController = rootViewController
        }

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("didReceiveRemoteNotification")
        notificationManager.handleNotification(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }

    // MARK: - Private

    @objc func didCompleteRegistration(notification: NSNotification) {
        guard let registration = notification.userInfo?[RegistrationCompleteNotificationRegistrationKey] as? Registration else {
            print("Registration NSNotification did not contain a registration")
            return
        }
        
        continueWithRegistration(registration)
    }
    
    func continueWithRegistration(_ registration: Registration) {
        guard let rootViewController = window?.rootViewController as? RootViewController else {
            return
        }

        broadcaster.setSonarUUID(registration.id)
        broadcaster.start(stateDelegate: nil)
        listener.start(stateDelegate: nil)

        appCoordinator = AppCoordinator(navController: rootViewController,
                                        persistance: persistance,
                                        secureRequestFactory: ConcreteSecureRequestFactory(registration: registration))
        appCoordinator.start()
    }

}
