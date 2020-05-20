//
//  ApplyForTestContainerViewController.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ApplyForTestContainerViewController: ReferenceCodeContainerViewControllerBase, Storyboarded {
    static let storyboardName = "ApplyForTest"
    
    override func instantiatePostLoadViewController(referenceCode: String?) -> UIViewController {
        let applyVc = ApplyForTestViewController.instantiate()
        applyVc.inject(referenceCode: referenceCode)
        return applyVc
    }
}
