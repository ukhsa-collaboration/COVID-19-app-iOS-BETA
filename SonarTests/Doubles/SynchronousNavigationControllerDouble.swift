//
//  SynchronousNavigationControllerDouble.swift
//  SonarTests
//
//  Created by NHSX on 5/21/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SynchronousNavigationControllerDouble: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
//        viewControllers.append(viewController)
    }
    
//    override var topViewController: UIViewController? {
//        viewControllers.last
//    }
}
