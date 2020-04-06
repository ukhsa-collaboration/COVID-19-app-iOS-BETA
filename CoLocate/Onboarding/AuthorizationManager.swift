//
//  AuthorizationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import Foundation

class AuthorizationManager: AuthorizationManaging {
    
    typealias Status = AuthorizationStatus
    
    var bluetooth: Status {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                fatalError()
            case .denied:
                return .denied
            case .allowedAlways:
                return .allowed
            @unknown default:
                fatalError()
            }
        } else {
            switch CBPeripheralManager.authorizationStatus() {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                fatalError()
            case .denied:
                return .denied
            case .authorized:
                return .allowed
            @unknown default:
                fatalError()
            }
        }
    }

    func notifications(completion: @escaping (Status) -> Void) {
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
