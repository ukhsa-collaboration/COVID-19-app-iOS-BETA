//
//  ViewControllerContainerDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class ViewControllerContainerDouble: ViewControllerContainer {
    var currentChild: UIViewController?
    
    func show(viewController: UIViewController) {
        currentChild = viewController
    }
}
