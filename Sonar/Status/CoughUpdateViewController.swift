//
//  CoughUpdateViewController.swift
//  Sonar
//
//  Created on 25/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CoughUpdateViewController: UIViewController, Storyboarded {
    static var storyboardName = "Status"
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    override func accessibilityPerformEscape() -> Bool {
        close(self)
        return true
    }
}
