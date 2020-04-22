//
//  StartNowViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StartNowViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var continueHandler: (() -> Void)! = nil
    
    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destination = segue.destination as? PrivacyViewController {
            destination.inject(continueHandler: continueHandler)
        }
    }
}
