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
    let acknowledgementUrl: String?
    let mostRecentProximityEventDate: String?
}

extension Exposed {
    enum Status: String, Codable {
        case potential = "Potential"
    }
}

class ExposedNotificationHandler {
    
    struct UserInfoDecodingError: Error {}
    
    let logger = Logger(label: "StatusNotificationHandler")
    let dateFormatter = ISO8601DateFormatter()

    let statusStateMachine: StatusStateMachining

    init(statusStateMachine: StatusStateMachining) {
        self.statusStateMachine = statusStateMachine
    }
    
    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            
            if
                let exposed = try? JSONDecoder().decode(Exposed.self, from: jsonData)
            {
                let exposedDate = exposed.mostRecentProximityEventDate.flatMap({ dateFormatter.date(from: $0) })
                statusStateMachine.exposed(on: exposedDate)
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
