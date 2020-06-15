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

    private var result: LinkingIdResult!

    func inject(result: LinkingIdResult) {
        self.result = result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

        switch result! {
        case .success(let code):
            errorWrapper.isHidden = true
            referenceCodeWrapper.isHidden = false
            referenceCodeLabel.text = code

            let pronouncableRefCode = code.map { String($0) }.joined(separator: ", ")
            referenceCodeWrapper.accessibilityLabel = "Your app reference code is \(pronouncableRefCode)"
            referenceCodeWrapper.accessibilityHint = "Copies the app reference code."

            copyButton.attributedText = NSAttributedString(string: "Copy", attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
            copyButton.textColor = UIColor.nhs.blue
        case .error(let error):
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
