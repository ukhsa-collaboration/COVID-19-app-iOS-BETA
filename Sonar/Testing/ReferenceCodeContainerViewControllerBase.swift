//
//  ReferenceCodeContainerViewControllerBase.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ReferenceCodeContainerViewControllerBase: UIViewController {
    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!
    private var started = false
    
    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }

        show(viewController: ReferenceCodeLoadingViewController.instantiate())

        linkingIdManager.fetchLinkingId { linkingId in
            self.uiQueue.async {
                let newChild = self.instantiatePostLoadViewController(referenceCode: linkingId)
                self.show(viewController: newChild)
                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
    }
    
    open func instantiatePostLoadViewController(referenceCode: String?) -> UIViewController {
        fatalError("Must override")
    }
    
    private func show(viewController newChild: UIViewController) {
        children.first?.willMove(toParent: nil)
        children.first?.viewIfLoaded?.removeFromSuperview()
        children.first?.removeFromParent()
        addChild(newChild)
        
        newChild.view.frame = view.bounds
        view.addSubview(newChild.view)
        newChild.didMove(toParent: self)
    }
}
