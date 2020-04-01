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
    let rootViewController = UIViewController()

    override func setUp() {
        super.setUp()

        Persistence.shared.clear()

        UIApplication.shared.windows.first?.rootViewController = rootViewController
    }
}

extension DispatchQueue {
    static let test = DispatchQueue(label: "test")

    func flush() {
        sync {}
    }
}
