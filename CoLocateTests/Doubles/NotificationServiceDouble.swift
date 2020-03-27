//
//  NotificationServiceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class NotificationManagerDouble: NotificationManager {
    var pushToken: String?

    var delegate: NotificationManagerDelegate?

    func configure() { }

    func requestAuthorization(application: Application, completion: @escaping (Result<Bool, Error>) -> Void) {
    }

    func handleNotification(userInfo: [AnyHashable : Any]) {
    }
}
