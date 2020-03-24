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
    static let shared = RequestFactory(deviceId: UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!)

    // TODO: this needs to be read from the keychain
    let dummyKey: SymmetricKey = SymmetricKey(data: Data(base64Encoded: "Gqacz+VE6uuZy1uc4oTG/A+LAS291mXN+J5opDSNYys=")!)

    let deviceId: UUID
    
    static func registrationRequest() -> RegistrationRequest {
        return RegistrationRequest()
    }

    init(deviceId: UUID) {
        self.deviceId = deviceId
    }

    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        return PatchContactEventsRequest(key: dummyKey, deviceId: deviceId, contactEvents: contactEvents)
    }
}
