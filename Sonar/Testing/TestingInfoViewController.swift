//
//  TestingInfoViewController.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TestingInfoViewController: UIViewController, Storyboarded {
    static let storyboardName = "TestingInfo"

    var linkingIdManager: LinkingIdManaging!
    var uiQueue: TestableQueue!

    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LinkingIdViewController {
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: uiQueue)
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.performSegue(withIdentifier: "UnwindFromTestingInfo", sender: nil)
        return true
    }
}
