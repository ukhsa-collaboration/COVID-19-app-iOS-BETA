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

        linkingIdManager.fetchLinkingId { linkingId, error in
            let linkingIdResult: LinkingIdResult
            if let linkingId = linkingId {
                linkingIdResult = .success(linkingId)
            } else if let error = error {
                linkingIdResult = .error(error)
            } else {
                assertionFailure("Expected a reference code or an error")
                linkingIdResult = .error("No reference code returned")
            }
            self.uiQueue.async {
                let newChild = self.vcProvider.map { $0(linkingIdResult) } ?? self.instantiatePostLoadViewController(referenceCode: linkingId, referenceError: error)
                self.show(viewController: newChild)
                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
    }
    
    open func instantiatePostLoadViewController(referenceCode: String?, referenceError: String?) -> UIViewController {
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
