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
        Registration(id: UUID(), secretKey: Data(), broadcastRotationKey: SecKey.sampleEllipticCurveKey)
    }
}

class FakeError: Error {
    static var fake: Error {
        FakeError()
    }
}

extension SecKey {
    static var sampleEllipticCurveKey: SecKey {
        let data = Data.init(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return try! BroadcastRotationKeyConverter().fromData(data)
    }
}
