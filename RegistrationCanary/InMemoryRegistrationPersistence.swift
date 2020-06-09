//
//  InMemoryRegistrationPersistence.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/9/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class InMemoryRegistrationPersistence: RegistrationPersisting {
    var registration: Registration?
    var registeredPushToken: String?
    var partialPostcode: String?
    var acknowledgmentUrls: Set<URL> = Set()
}
