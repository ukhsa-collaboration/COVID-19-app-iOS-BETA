//
//  AppDelegate.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var diagnosisService: DiagnosisService = DiagnosisService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        return true
    }
}

