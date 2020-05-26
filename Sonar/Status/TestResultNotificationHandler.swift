//
//  TestResultNotificationHandler.swift
//  Sonar
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

class TestResultNotificationHandler {
    
    struct UserInfoDecodingError: Error {}
    
    let logger = Logger(label: "StatusNotificationHandler")

    let statusStateMachine: StatusStateMachining

    init(statusStateMachine: StatusStateMachining) {
        self.statusStateMachine = statusStateMachine
    }
    
    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let testResult = try? decoder.decode(TestResult.self, from: jsonData) {
                statusStateMachine.received(testResult.result)
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
