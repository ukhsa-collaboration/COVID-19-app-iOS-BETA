//
//  BookTestContainerViewController.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BookTestContainerViewController: ReferenceCodeContainerViewControllerBase, Storyboarded {
    static let storyboardName = "BookTest"
    
    override func instantiatePostLoadViewController(referenceCode: String?) -> UIViewController {
        let vc = BookTestViewController.instantiate()
        vc.inject(referenceCode: referenceCode)
        return vc
    }
}
