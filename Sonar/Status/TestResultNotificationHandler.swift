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
    let userNotificationCenter: UserNotificationCenter

    init(
        statusStateMachine: StatusStateMachining,
        userNotificationCenter: UserNotificationCenter
    ) {
        self.statusStateMachine = statusStateMachine
        self.userNotificationCenter = userNotificationCenter
    }
    
    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let testResult = try? decoder.decode(TestResult.self, from: jsonData) {
                statusStateMachine.received(testResult)
            } else {
                throw UserInfoDecodingError()
            }
            
            let scheduler = HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
            scheduler.scheduleLocalNotification(
                title: nil,
                body:
                "Your test result has arrived. Please open the app to learn what to do next. You have been sent an email with more information",
                interval: 10,
                identifier: "testResult.arrived",
                repeats: false
            )
            
            completion(.newData)
        } catch {
            logger.error("Unable to process test result notification: '\(String(describing: userInfo))'")
            completion(.noData)
            return
        }
    }

}
