//
//  AuthorizationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import Foundation

class AuthorizationManager {

    enum Status {
        // Purposefully not handling the denied case for now
        // since we don't have any UI for handling when a user
        // disables bluetooth/notifications after allowing it
        // initially.
        case notDetermined, allowed //, denied
    }

    var bluetooth: Status {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                fatalError()
            case .denied:
                fatalError()
            case .allowedAlways:
                return .allowed
            @unknown default:
                fatalError()
            }
        } else {
            let manager = CBCentralManager()
            switch manager.state {
            case .unknown:
                fatalError()
            case .resetting:
                fatalError()
            case .unsupported:
                fatalError()
            case .unauthorized:
                fatalError()
            case .poweredOff:
                fatalError()
            case .poweredOn:
                fatalError()
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
                fatalError()
            case .authorized:
                completion(.allowed)
            case .provisional:
                fatalError()
            @unknown default:
                fatalError()
            }
        }
    }

}
