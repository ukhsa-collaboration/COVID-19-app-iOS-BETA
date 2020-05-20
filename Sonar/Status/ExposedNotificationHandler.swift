//
//  StatusNotificationHandler.swift
//  Sonar
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

fileprivate struct Exposed: Codable {
    let status: Status
    let type: String?
    let acknowledgementUrl: String?
}

extension Exposed {
    enum Status: String, Codable {
        case potential = "Potential"
    }
}

class ExposedNotificationHandler {
    
    struct UserInfoDecodingError: Error {}
    
    let logger = Logger(label: "StatusNotificationHandler")

    let statusStateMachine: StatusStateMachining

    init(statusStateMachine: StatusStateMachining) {
        self.statusStateMachine = statusStateMachine
    }
    
    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            
            if let _ = try? JSONDecoder().decode(Exposed.self, from: jsonData) {
                statusStateMachine.exposed()
            } else {
                throw UserInfoDecodingError()
            }
            completion(.newData)
        } catch {
            logger.warning("Received unexpected status from remote notification: '\(String(describing: userInfo["status"]))'")
            completion(.noData)
            return
        }
    }

}
