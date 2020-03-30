//
//  SecureRequestFactory.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

protocol SecureRequestFactory {
    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest
}

struct ConcreteSecureRequestFactory: SecureRequestFactory {
    private let registration: Registration

    init(registration: Registration) {
        self.registration = registration
    }

    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        let symmetricKey = SymmetricKey(data: registration.secretKey)

        return PatchContactEventsRequest(key: symmetricKey, sonarId: registration.id, contactEvents: contactEvents)
    }
}
