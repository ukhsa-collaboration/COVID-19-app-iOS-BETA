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
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, DiagnosisServiceDelegate {

    var window: UIWindow?

    var broadcaster: BTLEBroadcaster?
    var listener: BTLEListener?

    let notificationManager = NotificationManager()
    let diagnosisService = DiagnosisService.shared
    
    override init() {
        super.init()
        diagnosisService.delegate = self
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        initNotifications()
        initUi()

        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // This fires when we tap on the notification

        notificationManager.handleNotification(userInfo: userInfo)
    }
    
    func diagnosisService(_ diagnosisService: DiagnosisService, didRecordDiagnosis diagnosis: Diagnosis) {
        if diagnosis == .potential {
            window?.rootViewController = potentialController()
        }
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
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
        let rootViewController: UIViewController?

        switch diagnosisService.currentDiagnosis {

        case .unknown:
            rootViewController = mainStoryboard.instantiateInitialViewController()

        case .infected:
            rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "navigationController")
            (rootViewController as? UINavigationController)?.pushViewController(mainStoryboard.instantiateViewController(withIdentifier: "pleaseSelfIsolate"), animated: false)

        case .notInfected:
            rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "navigationController")
            (rootViewController as? UINavigationController)?.pushViewController(mainStoryboard.instantiateViewController(withIdentifier: "okNowViewController"), animated: false)
            
        case.potential:
            rootViewController = potentialController()
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
    
    private func potentialController() -> UIViewController {
        return UIStoryboard.init(name: "Potential", bundle: nil).instantiateInitialViewController()!
    }
}
