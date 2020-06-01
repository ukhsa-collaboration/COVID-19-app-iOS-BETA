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
    
    private var referenceCode: String?
    private var referenceError: String?

    func inject(referenceCode: String?, referenceError: String?) {
        self.referenceCode = referenceCode
        self.referenceError = referenceError
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode, error: referenceError)
        }
    }
}
