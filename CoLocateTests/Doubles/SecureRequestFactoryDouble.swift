//
//  SecureRequestFactoryDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

@testable import CoLocate

class SecureRequestFactoryDouble: SecureRequestFactory {
    func patchContactsRequest(contactEvents: [ContactEvent]) -> PatchContactEventsRequest {
        return PatchContactEventsRequest(key: SymmetricKey(size: SymmetricKeySize.bits128), sonarId: UUID(), contactEvents: [])
    }
}
