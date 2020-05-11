//
//  ConcreteBroadcastIdEncrypterProviderTests.swift
//  SonarTests
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ConcreteBroadcastIdEncrypterProviderTests: XCTestCase {

    func testReturnsNilWhenRegistrationIsNil() {
        let persistence = PersistenceDouble(registration: nil)
        let provider = ConcreteBroadcastIdEncrypterProvider(persistence: persistence)
        
        XCTAssertNil(provider.getEncrypter())
    }
    
    func testReturnsRealEncrypterWhenSonarIdAndSecKeyPresent() {
        let registration = Registration(sonarId: UUID(), secretKey: SecKey.sampleHMACKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
        let persistence = PersistenceDouble(registration: registration)
        let provider = ConcreteBroadcastIdEncrypterProvider(persistence: persistence)
        
        XCTAssertNotNil(provider.getEncrypter())
    }

}
