//
//  MedicalWorkerInstructionsViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class MedicalWorkerInstructionsViewController: UIViewController, Storyboarded {
    static var storyboardName = "Status"
    
    override func accessibilityPerformEscape() -> Bool {
        self.performSegue(withIdentifier: "UnwindFromMedicalWorkerInstructions", sender: nil)
        return true
    }
}
