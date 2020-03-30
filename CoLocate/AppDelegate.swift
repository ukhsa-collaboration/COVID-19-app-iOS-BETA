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
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, RegistrationCoordinatorDelegate {
    var window: UIWindow?

    var broadcaster: BTLEBroadcaster?
    var listener: BTLEListener?

    let notificationManager: NotificationManager = ConcreteNotificationManager()
    let diagnosisService: DiagnosisService = DiagnosisService.shared
    let registrationService: RegistrationService

    var appCoordinator: AppCoordinator!
    var registrationCoordinator: RegistrationCoordinator!
    
    override init() {
        registrationService = ConcreteRegistrationService(session: URLSession.shared, notificationManager: notificationManager)
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let rootViewController = RootViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController

        registrationCoordinator = RegistrationCoordinator(application: application,
                                                          navController: rootViewController,
                                                          notificationManager: notificationManager,
                                                          registrationService: registrationService,
                                                          registrationStorage: SecureRegistrationStorage.shared,
                                                          delegate: self)
        registrationCoordinator.start()
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(#file) \(#function)")

        notificationManager.handleNotification(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }

    // MARK: - Private

    func didCompleteRegistration(_ registration: Registration) {
        guard let rootViewController = window?.rootViewController as? RootViewController else {
            return
        }

        // FIXME: on second launch this is nil
        broadcaster?.setSonarUUID(registration.id)

        appCoordinator = AppCoordinator(navController: rootViewController,
                                        diagnosisService: diagnosisService,
                                        secureRequestFactory: ConcreteSecureRequestFactory(registration: registration))
        appCoordinator.start()
    }

}
