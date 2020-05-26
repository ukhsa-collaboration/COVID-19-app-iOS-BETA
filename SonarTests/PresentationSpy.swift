//
//  PresentationSpy.swift
//  SonarTests
//
//  Created by NHSX on 5/26/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

private let kPresented = "PresentationSpy_presented"

// A UIViewController's presentedViewController property isn't reliably updated synchronously,
// even when animated: false is passed. That makes it difficult to reliably test interactions
// that cross presentation boundaries without resorting to slow UI tests. This class solves that
// problem.
//
// Example usage:
//
// func testSomthing() throws {
//     try PresentationSpy.withSpy {
//         let vc = someViewController()
//         makePresentationHappen()
//         XCTAssertNotNil(PresentationSpy.presented(by: vc) as? SomeClass
//         makeDismissalHappen()
//         XCTAssertNil(PrsentationSpy.presented(by: vc)
//     }
// }
class PresentationSpy {
    class func withSpy(_ block: () throws -> Void) throws {
        try UIViewController.swizzleDoUnswizzle(
            real: #selector(UIViewController.present(_:animated:completion:)),
            fake: #selector(UIViewController.presentObservably(_:animated:completion:)),
            parking: #selector(UIViewController.parkedRealPresent(_:animated:completion:))
        ) {
            try UIViewController.swizzleDoUnswizzle(
                real: #selector(UIViewController.dismiss(animated:completion:)),
                fake: #selector(UIViewController.dismissObservably(animated:completion:)),
                parking: #selector(UIViewController.parkedRealDismiss(animated:completion:)),
                block: block)
        }
    }
    
    class func presented(by presenting: UIViewController) -> UIViewController? {
        return objc_getAssociatedObject(presenting, kPresented) as? UIViewController
    }
}

private extension UIViewController {
    class func swizzleDoUnswizzle(real: Selector, fake: Selector, parking: Selector, block: () throws -> Void) throws {
        let realMethod = class_getInstanceMethod(self, real)!
        let fakeMethod = class_getInstanceMethod(self, fake)!
        let parkingMethod = class_getInstanceMethod(self, parking)!
        
        method_exchangeImplementations(realMethod, parkingMethod)
        method_exchangeImplementations(realMethod, fakeMethod)

        defer {
            method_exchangeImplementations(realMethod, fakeMethod)
            method_exchangeImplementations(realMethod, parkingMethod)
        }
        
        try block()
    }
    
    @objc func presentObservably(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        parkedRealPresent(viewControllerToPresent, animated: animated, completion: completion)
        objc_setAssociatedObject(self, kPresented, viewControllerToPresent, .OBJC_ASSOCIATION_ASSIGN) // TODO: or OBJC_ASSOCIATION_RETAIN_NONATOMIC?
    }
    
    @objc func parkedRealPresent(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        fatalError("parkedRealPresent's actual implementation was called")
    }
    
    @objc func dismissObservably(animated: Bool, completion: (() -> Void)? = nil) {
        parkedRealDismiss(animated: animated, completion: completion)
        print("Swizzled dismissObservably got called!")
        objc_setAssociatedObject(self, kPresented, nil, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    @objc func parkedRealDismiss(animated: Bool, completion: (() -> Void)? = nil) {
        fatalError("parkedRealDismiss's actual implementation was called")
    }
}
