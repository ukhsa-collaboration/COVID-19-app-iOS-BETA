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

    let notificationManager = NotificationManager()
    let diagnosisService = DiagnosisService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        initNotifications()
        initUi()

        return true
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
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let rootViewController: UIViewController?

        switch diagnosisService.currentDiagnosis {

        case .unknown:
            rootViewController = storyboard.instantiateInitialViewController()

        case .infected:
            rootViewController = storyboard.instantiateViewController(withIdentifier: "navigationController")
            (rootViewController as? UINavigationController)?.pushViewController(storyboard.instantiateViewController(withIdentifier: "pleaseSelfIsolate"), animated: false)

        case .notInfected:
            rootViewController = storyboard.instantiateViewController(withIdentifier: "navigationController")
            (rootViewController as? UINavigationController)?.pushViewController(storyboard.instantiateViewController(withIdentifier: "okNowViewController"), animated: false)
        case.potential:
            rootViewController = storyboard.instantiateInitialViewController()
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
}
