//
//  TestHelpers.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import XCTest
@testable import Sonar

func inWindowHierarchy(viewController: UIViewController, closure: (() -> Void)) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.window?.rootViewController = viewController

    closure()

    appDelegate.window?.rootViewController = nil
}

class TestCase: XCTestCase {
    let parentViewControllerForTests = UINavigationController()

    override func setUp() {
        super.setUp()

        // TODO: This is quite error prone. Mock out the dependencies so we don’t have to do this.
        // Tests verifying actual storage must explicitly do so.
        let persistence = Persistence(
            secureRegistrationStorage: SecureRegistrationStorage(),
            broadcastKeyStorage: SecureBroadcastRotationKeyStorage(),
            monitor: AppMonitoringDouble()
        )
        persistence.clear()

        UIApplication.shared.windows.first?.rootViewController = parentViewControllerForTests
    }
}

extension DispatchQueue {
    static let test = DispatchQueue(label: "test")

    func flush() {
        sync {}
    }
}

extension Registration {
    static var fake: Self {
        Registration(id: UUID(), secretKey: Data(), broadcastRotationKey: knownGoodECPublicKey())
    }
}

class FakeError: Error {
    static var fake: Error {
        FakeError()
    }
}

// TODO: we probably don't need both this and sampleEllipticCurveKey
func knownGoodECPublicKey() -> SecKey {
    let base64EncodedKey = "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="

    let data = Data.init(base64Encoded: base64EncodedKey)!

    let keyDict : [NSObject:NSObject] = [
       kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
       kSecAttrKeyClass: kSecAttrKeyClassPublic,
       kSecAttrKeySizeInBits: NSNumber(value: 256),
       kSecReturnPersistentRef: true as NSObject
    ]

    return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
}

extension SecKey {
    static var sampleEllipticCurveKey: SecKey {
        let data = Data.init(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return try! BroadcastRotationKeyConverter().fromData(data)
    }
}
