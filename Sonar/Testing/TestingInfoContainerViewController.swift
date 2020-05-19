//
//  TestingInfoContainerViewController.swift
//  Sonar
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TestingInfoContainerViewController: UIViewController, Storyboarded {
    static let storyboardName = "TestingInfo"
        
    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!
    private var started = false
    
    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !started else { return }
        
        show(viewController: ReferenceCodeLoadingViewController.instantiate())
        
        linkingIdManager.fetchLinkingId { linkingId in
            self.uiQueue.async {
                let testingInfoVc = TestingInfoViewController.instantiate()
                testingInfoVc.inject(referenceCode: linkingId)
                self.show(viewController: testingInfoVc)
                
                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.performSegue(withIdentifier: "UnwindFromTestingInfo", sender: nil)
        return true
    }
    
    func show(viewController newChild: UIViewController) {
        children.first?.willMove(toParent: nil)
        children.first?.viewIfLoaded?.removeFromSuperview()
        children.first?.removeFromParent()
        addChild(newChild)
        
        newChild.view.frame = view.bounds
        view.addSubview(newChild.view)
        newChild.didMove(toParent: self)
    }
}
