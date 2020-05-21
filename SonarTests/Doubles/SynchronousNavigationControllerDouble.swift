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
        viewControllers.append(viewController)
    }
}
