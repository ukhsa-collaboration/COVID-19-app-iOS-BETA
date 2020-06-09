//
//  Persisting.swift
//  Sonar
//
//  Created by NHSX on 6/9/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct HMACKey: Equatable, Codable {
    let data: Data
}

struct Registration: Equatable {
    let sonarId: UUID
    let secretKey: HMACKey
    let broadcastRotationKey: SecKey
}

protocol RegistrationPersisting {
    var registration: Registration? { get nonmutating set }
    var registeredPushToken: String? { get nonmutating set }
    var partialPostcode: String? { get nonmutating set }
    var acknowledgmentUrls: Set<URL> { get nonmutating set }
}
