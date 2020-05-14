//
//  SymptomsPromptViewController.swift
//  Sonar
//
//  Created by NHSX on 4/20/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomsPromptViewController: UIViewController, Storyboarded {
    static var storyboardName = "Status"

    var completion: ((_ needsCheckin: Bool) -> Void)!

    func inject(
        completion: @escaping (_ needsCheckin: Bool) -> Void
    ) {
        self.completion = completion
    }
    
    @IBAction func updateSymptoms(_ sender: Any) {
        completion(true)
    }
    
    @IBAction func noSymptoms(_ sender: Any) {
        completion(false)
    }
}
