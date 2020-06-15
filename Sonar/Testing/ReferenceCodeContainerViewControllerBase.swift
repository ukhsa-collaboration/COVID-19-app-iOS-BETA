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
    private var vcProvider: ((LinkingIdResult) -> UIViewController)?
    private var started = false
    
    func inject(
        linkingIdManager: LinkingIdManaging,
        uiQueue: TestableQueue,
        vcProvider: ((LinkingIdResult) -> UIViewController)? = nil
    ) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
        self.vcProvider = vcProvider
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }

        show(viewController: ReferenceCodeLoadingViewController.instantiate())

        linkingIdManager.fetchLinkingId { result in
            self.uiQueue.async {
                let newChild = self.vcProvider.map { $0(result) } ?? self.instantiatePostLoadViewController(result: result)
                self.show(viewController: newChild)
                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
    }
    
    open func instantiatePostLoadViewController(result: LinkingIdResult) -> UIViewController {
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
