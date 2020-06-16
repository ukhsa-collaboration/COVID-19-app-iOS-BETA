//
//  AuthorizationManager.swift
//  Sonar
//
//  Created by NHSX on 3/31/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class AuthorizationManager: AuthorizationManaging {
    
    // WARNING: Don't call this except in situations where it's certain that the nursery will
    // have been started already (or at least, very soon). If the nursery is not started, the
    // completion handler will never be called.
    func waitForDeterminedBluetoothAuthorizationStatus(
        completion: @escaping (BluetoothAuthorizationStatus) -> Void
    ) {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if #available(iOS 13.1, *) {
                switch SonarBTManager.authorization {
                case .notDetermined:
                    return
                    
                case .allowedAlways:
                    completion(.allowed)
                    timer.invalidate()
                    
                default:
                    completion(.denied)
                    timer.invalidate()
                }
            } else {
                switch SonarBTPeripheralManager.authorizationStatus() {
                    
                case .notDetermined:
                    return
                    
                case .authorized:
                    completion(.allowed)
                    timer.invalidate()
                    
                default:
                    completion(.denied)
                    timer.invalidate()
                }
            }
        }
    }
    
    var bluetooth: BluetoothAuthorizationStatus {
        if #available(iOS 13.1, *) {
            switch SonarBTManager.authorization {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .denied
            case .denied:
                return .denied
            case .allowedAlways:
                return .allowed
            @unknown default:
                fatalError()
            }
        } else {
            switch SonarBTPeripheralManager.authorizationStatus() {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .denied
            case .denied:
                return .denied
            case .authorized:
                return .allowed
            @unknown default:
                fatalError()
            }
        }
    }

    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.getNotificationSettings { notificationSettings in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                completion(.notDetermined)
            case .denied:
                completion(.denied)
            case .authorized:
                completion(.allowed)
            case .provisional:
                // We should only ever get these if we request .provisional notification
                // authorization, and since we don't, this should never happen.
                fatalError()
            @unknown default:
                fatalError()
            }
        }
    }

}
