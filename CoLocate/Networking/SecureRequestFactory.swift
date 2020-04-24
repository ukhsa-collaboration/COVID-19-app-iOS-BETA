//
//  SecureRequestFactory.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol SecureRequestFactory {
    func patchContactsRequest(symptomsTimestamp: Date, contactEvents: [ContactEvent]) -> PatchContactEventsRequest
}

struct ConcreteSecureRequestFactory: SecureRequestFactory {
    private let registration: Registration

    init(registration: Registration) {
        self.registration = registration
    }

    func patchContactsRequest(symptomsTimestamp: Date, contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        return PatchContactEventsRequest(
            key: registration.secretKey,
            sonarId: registration.id,
            symptomsTimestamp: symptomsTimestamp,
            contactEvents: contactEvents
        )
    }
}
