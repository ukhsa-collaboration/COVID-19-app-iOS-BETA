//
//  NotificationAcknowledgerDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class NotificationAcknowledgerDouble: NotificationAcknowledger {
    convenience init() {
        self.init(persisting: PersistenceDouble(), session: SessionDouble())
    }

    var userInfo: [AnyHashable : Any]?
    var ackResult = false
    override func ack(userInfo: [AnyHashable : Any]) -> Bool {
        self.userInfo = userInfo
        return ackResult
    }
}
