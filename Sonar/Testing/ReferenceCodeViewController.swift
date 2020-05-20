//
//  ReferenceCodeViewController.swift
//  Sonar
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ReferenceCodeViewController: UIViewController, Storyboarded {
    static let storyboardName = "ReferenceCode"
    
    @IBOutlet var errorWrapper: UIView!
    @IBOutlet var referenceCodeWrapper: UIView!
    @IBOutlet var referenceCodeLabel: UILabel!

    private var referenceCode: String?
    
    func inject(referenceCode: String?) {
        self.referenceCode = referenceCode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let referenceCode = referenceCode {
            errorWrapper.isHidden = true
            referenceCodeWrapper.isHidden = false
            referenceCodeLabel.text = referenceCode
        } else {
            errorWrapper.isHidden = false
            referenceCodeWrapper.isHidden = true
        }
    }

    @IBAction func copyTapped() {
        UIPasteboard.general.string = referenceCodeLabel.text

        // This is an arbitrary dev animation to fade the
        // reference code view so the user knows we actually
        // did something when they tap "copy".
        UIView.animate(withDuration: 0.2, animations: {
            self.referenceCodeWrapper.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.referenceCodeWrapper.alpha = 1
            })
        })
    }

}
