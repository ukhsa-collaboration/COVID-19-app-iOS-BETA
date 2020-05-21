//
//  UpdatePushNotificationTokenRequest.swift
//  Sonar
//
//  Created by NHSX on 21/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class UpdatePushNotificationTokenRequest: SecureRequest, Request {
    var method: HTTPMethod
    var urlable: Urlable
    
    func parse(_ data: Data) throws -> Void {
        
    }
    
    typealias ResponseType = Void

    init(registration: Registration, token: String) {
        try! method = .put(data: JSONEncoder().encode(["pushNotificationToken": token, "sonarId": registration.sonarId.uuidString]))
        urlable = .path("")
        super.init(HMACKey(data: Data()), Data(), [:])
    }
}
