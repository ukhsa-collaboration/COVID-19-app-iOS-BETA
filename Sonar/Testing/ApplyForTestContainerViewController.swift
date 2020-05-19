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
    
    private var urlOpener: TestableUrlOpener!

    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue, urlOpener: TestableUrlOpener) {
        inject(linkingIdManager: linkingIdManager, uiQueue: uiQueue)
        self.urlOpener = urlOpener
    }

    override func instantiatePostLoadViewController(referenceCode: String?) -> UIViewController {
        let applyVc = ApplyForTestViewController.instantiate()
        applyVc.inject(urlOpener: self.urlOpener, referenceCode: referenceCode)
        return applyVc
    }
}
