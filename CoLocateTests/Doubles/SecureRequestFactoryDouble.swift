//
//  SecureRequestFactoryDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto

@testable import CoLocate

class SecureRequestFactoryDouble: SecureRequestFactory {
    func patchContactsRequest(contactEvents: [OldContactEvent]) -> PatchContactEventsRequest {
        let key = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        return PatchContactEventsRequest(key: key, sonarId: UUID(), contactEvents: [])
    }
}
