//
//  UpdatePushNotificationTokenRequest.swift
//  Sonar
//
//  Created by NHSX on 21/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class UpdatePushNotificationTokenRequest: SecureRequest, Request {
    typealias ResponseType = Void

    var method: HTTPMethod
    var urlable: Urlable

    func parse(_ data: Data) throws -> Void {}

    init(registration: Registration, token: String) {
        let data = try! JSONEncoder().encode(["pushNotificationToken": token, "sonarId": registration.sonarId.uuidString])
        method = .put(data: data)
        urlable = .path("/api/registration/push-notification-token")
        super.init(registration.secretKey, data, ["Content-Type": "application/json"])
    }
}
