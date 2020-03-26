//
//  NotificationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

import Firebase

class NotificationManager: NSObject {

    let uiQueue: DispatchQueue
    let firebase: TestableFirebaseApp.Type
    let messagingFactory: () -> TestableMessaging
    let userNotificationCenter: UserNotificationCenter
    let diagnosisService: DiagnosisService

    init(
        uiQueue: DispatchQueue,
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        diagnosisService: DiagnosisService
    ) {
        self.uiQueue = uiQueue
        self.firebase = firebase
        self.messagingFactory = messagingFactory
        self.userNotificationCenter = userNotificationCenter
        self.diagnosisService = diagnosisService

        super.init()
    }

    convenience override init() {
        self.init(
            uiQueue: DispatchQueue.main,
            firebase: FirebaseApp.self,
            messagingFactory: { Messaging.messaging() },
            userNotificationCenter: UNUserNotificationCenter.current(),
            diagnosisService: DiagnosisService()
        )
    }

    func configure() {
        firebase.configure()
        messagingFactory().delegate = self
        userNotificationCenter.delegate = self
    }

    func requestAuthorization(
        application: Application,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        userNotificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.uiQueue.sync {
                application.registerForRemoteNotifications()
            }
            completion(.success(granted))
        }
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) {
        guard let diagnosis = userInfo["diagnosis"] else {
            print("no diagnosis in user info \(userInfo)")
            return
        }
        
        print("Got notification with diagnosis \(diagnosis))")
        
        if diagnosis as? String == "potential" {
            diagnosisService.recordDiagnosis(.potential)
        }
    }

}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // This only happens when we are in the foregrond?

        handleNotification(userInfo: notification.request.content.userInfo)

        // How to re-present notification?
//        completionHandler([.alert, .badge, .sound])
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Remote instance ID token: \(fcmToken)")
    }
}

// MARK: - Testable

protocol Application {
    func registerForRemoteNotifications()
}

extension UIApplication: Application {
}

protocol TestableFirebaseApp {
    static func configure()
}

extension FirebaseApp: TestableFirebaseApp {
}

protocol TestableMessaging: class {
    var delegate: MessagingDelegate? { get set }
}

extension Messaging: TestableMessaging {
}

protocol UserNotificationCenter: class {
    var delegate: UNUserNotificationCenterDelegate? { get set }

    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, Error?) -> Void
    )
}

extension UNUserNotificationCenter: UserNotificationCenter {
}
