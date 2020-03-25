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
    let userNotificationCenter: UserNotificationCenter

    init(
        uiQueue: DispatchQueue,
        firebase: TestableFirebaseApp.Type,
        userNotificationCenter: UserNotificationCenter
    ) {
        self.uiQueue = uiQueue
        self.firebase = firebase
        self.userNotificationCenter = userNotificationCenter

        super.init()

        userNotificationCenter.delegate = self
    }

    convenience override init() {
        self.init(
            uiQueue: DispatchQueue.main,
            firebase: FirebaseApp.self,
            userNotificationCenter: UNUserNotificationCenter.current()
        )
    }

    func configure() {
        firebase.configure()
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

}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("will present a notification \(notification)")

        let userInfo = notification.request.content.userInfo
        guard let diagnosis = userInfo["diagnosis"] else {
            print("no diagnosis in user info \(userInfo)")
            return
        }

        print("the diagnosis is bad :: \(diagnosis)")
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

protocol UserNotificationCenter: class {
    var delegate: UNUserNotificationCenterDelegate? { get set }

    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, Error?) -> Void
    )
}

extension UNUserNotificationCenter: UserNotificationCenter {
}
