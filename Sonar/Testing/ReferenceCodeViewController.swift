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
    @IBOutlet weak var referenceCodeError: UILabel!
    @IBOutlet weak var copyButton: UILabel!

    private var referenceCode: String?
    private var error: String?
    
    func inject(referenceCode: String?, error: String?) {
        self.referenceCode = referenceCode
        self.error = error
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
            
            copyButton.attributedText = NSAttributedString(string: "Copy", attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
            copyButton.textColor = UIColor.nhs.blue
        } else {
            errorWrapper.isHidden = false
            referenceCodeWrapper.isHidden = true
            referenceCodeError.text = error
        }
    }

    @IBAction func copyTapped() {
        UIPasteboard.general.string = referenceCodeLabel.text
        copyButton.text = "COPIED".localized
        UIAccessibility.post(notification: .layoutChanged, argument: copyButton)
    }

}
