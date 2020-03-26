//
//  File.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

struct RequestFactory {

    // This uuid is pre-seeded on the database (for now)
    // this won't work if the database is dropped and recreated
    // this will change once we can store and read the deviceId we receive during registration
    static let shared = RequestFactory(deviceId: UUID(uuidString: "ba64976f-e2f8-4841-b505-e3a3c1dd820d")!)
    
    static let pushToken = "this should be the base64-encoded push token we get from firebase=="

    // TODO: this needs to be read from the keychain
    let dummyKey: SymmetricKey = SymmetricKey(data: Data(base64Encoded: "3bLIKs9B9UqVfqGatyJbiRGNW8zTBr2tgxYJh/el7pc=")!)

    let deviceId: UUID
    
    static func registrationRequest() -> RegistrationRequest {
        return RegistrationRequest(pushToken: pushToken)
    }

    init(deviceId: UUID) {
        self.deviceId = deviceId
    }

    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        return PatchContactEventsRequest(key: dummyKey, deviceId: deviceId, contactEvents: contactEvents)
    }
}
