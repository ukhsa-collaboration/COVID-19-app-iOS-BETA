//
//  TestHelpers.swift
//  SonarTests
//
//  Created by NHSX on 3/24/20.
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
            monitor: AppMonitoringDouble(),
            storageChecker: StorageCheckingDouble()
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
        Registration(sonarId: UUID(), secretKey: SecKey.sampleHMACKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
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
    
    static var knownGoodECPublicKey: SecKey {
        let data = Data(base64Encoded: "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI=")!

        let keyDict: [NSObject: NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
    }
    
    static var sampleHMACKey: HMACKey = HMACKey(data: Data(base64Encoded: "LWbqBBxfV5vob3ApsPhgOI8aiFcKYP8jLQ2fKb8Y1C0=")!)

}

extension Date {
    
    var midday: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    var followingMidnightUTC: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: self)!)
    }

}

extension IncomingBroadcastPayload {
    
    static var sample1: IncomingBroadcastPayload {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(1).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(1).networkByteOrderData)
        return IncomingBroadcastPayload(data: data)
    }
    
    static var sample2: IncomingBroadcastPayload {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(2).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(2).networkByteOrderData)
        return IncomingBroadcastPayload(data: data)
    }
    
    static var sample3: IncomingBroadcastPayload {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(3).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(3).networkByteOrderData)
        return IncomingBroadcastPayload(data: data)
    }

}
