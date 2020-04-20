//
//  TestHelpers.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import XCTest
@testable import CoLocate

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

        Persistence.shared.clear()

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
