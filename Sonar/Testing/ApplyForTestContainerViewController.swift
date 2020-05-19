//
//  ApplyForTestContainerViewController.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ApplyForTestContainerViewController: UIViewController, Storyboarded {
    static let storyboardName = "ApplyForTest"

    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!
    private var urlOpener: TestableUrlOpener!
    private var started = false
    
    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue, urlOpener: TestableUrlOpener) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
        self.urlOpener = urlOpener
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }

        show(viewController: ReferenceCodeLoadingViewController.instantiate())

        linkingIdManager.fetchLinkingId { linkingId in
            self.uiQueue.async {
                let applyVc = ApplyForTestViewController.instantiate()
                applyVc.inject(urlOpener: self.urlOpener, referenceCode: linkingId)
                self.show(viewController: applyVc)

                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
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
