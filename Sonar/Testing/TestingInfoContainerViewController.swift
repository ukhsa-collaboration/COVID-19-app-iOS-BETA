//
//  TestingInfoContainerViewController.swift
//  Sonar
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TestingInfoContainerViewController: ReferenceCodeContainerViewControllerBase, Storyboarded {
    static let storyboardName = "TestingInfo"
        
    override func instantiatePostLoadViewController(referenceCode: String?) -> UIViewController {
        let testingInfoVc = TestingInfoViewController.instantiate()
        testingInfoVc.inject(referenceCode: referenceCode)
        return testingInfoVc
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.performSegue(withIdentifier: "UnwindFromTestingInfo", sender: nil)
        return true
    }
    
}
