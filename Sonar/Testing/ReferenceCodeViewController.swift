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
    @IBOutlet weak var copyButton: ButtonWithDynamicType!

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

            let pronouncableRefCode = referenceCode.map { String($0) }.joined(separator: ", ")
            referenceCodeWrapper.accessibilityLabel = "Your app reference code is \(pronouncableRefCode)"
            referenceCodeWrapper.accessibilityHint = "Copies the app reference code."
        } else {
            errorWrapper.isHidden = false
            referenceCodeWrapper.isHidden = true
        }
    }

    @IBAction func copyTapped() {
        UIPasteboard.general.string = referenceCodeLabel.text
        copyButton.setTitle("COPIED".localized, for: .normal)
        UIAccessibility.post(notification: .layoutChanged, argument: copyButton)
    }

}
