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
        Registration(id: UUID(), secretKey: Data(), broadcastRotationKey: nil)
    }
}

class FakeError: Error {
    static var fake: Error {
        FakeError()
    }
}
