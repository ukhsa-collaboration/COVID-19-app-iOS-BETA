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

    static let shared = RequestFactory(registrationStorage: SecureRegistrationStorage.shared)
    static let pushToken = "this should be the base64-encoded push token we get from firebase=="

    static func registrationRequest() -> RegistrationRequest {
        return RegistrationRequest(pushToken: pushToken)
    }
    
    static func confirmRegistrationRequest(activationCode: String, pushToken: String) -> ConfirmRegistrationRequest {
        return ConfirmRegistrationRequest(activationCode: activationCode, pushToken: pushToken)
    }

    private let registrationStorage: SecureRegistrationStorage

    init(registrationStorage: SecureRegistrationStorage) {
        self.registrationStorage = registrationStorage
    }

    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        let registration = try! registrationStorage.get()!

        let deviceId = registration.id
        let symmetricKey = SymmetricKey(data: registration.secretKey)

        return PatchContactEventsRequest(key: symmetricKey, deviceId: deviceId, contactEvents: contactEvents)
    }
}
