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

    var broadcaster: BTLEBroadcaster?
    var listener: BTLEListener?

    let notificationManager: NotificationManager = ConcreteNotificationManager()
    let diagnosisService: DiagnosisService = DiagnosisService.shared
    let registrationService: RegistrationService

    var appCoordinator: AppCoordinator!
    
    override init() {
        registrationService = ConcreteRegistrationService(session: URLSession.shared, notificationManager: notificationManager)
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        initNotifications()
        initUi()

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(#file) \(#function)")

        notificationManager.handleNotification(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // MARK: - Private

    private func initNotifications() {
        notificationManager.configure()
        notificationManager.requestAuthorization(application: UIApplication.shared) { (result) in
            // TODO
            if case .failure(let error) = result {
                print(error)
            }
        }
    }

    private func initUi() {
        let rootViewController = RootViewController()
        appCoordinator = AppCoordinator(navController: rootViewController,
                                        diagnosisService: diagnosisService,
                                        notificationManager: notificationManager,
                                        registrationService: registrationService)

        appCoordinator.start()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
    
}
