//
//  PrivacyViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PrivacyViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var continueHandler: (() -> Void)! = nil
    
    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }

    @IBAction func continueTapped() {
        self.continueHandler()
    }
}
