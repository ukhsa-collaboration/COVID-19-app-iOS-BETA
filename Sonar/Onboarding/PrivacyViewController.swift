//
//  PrivacyViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PrivacyViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var continueHandler: (() -> Void)! = nil

    @IBOutlet weak var readMorePrivacyPolicyAndTermsConditions: UITextView!
    
    override func viewDidLoad() {
        // Full text : Read more about the app, the privacy policy, and all terms and conditions.

        let fullText = readMorePrivacyPolicyAndTermsConditions.text!
        let attributedString = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor(named: "NHS Text")! ,
        ])

        let range1 = NSRange(fullText.range(of: "about the app")!, in: fullText)
        attributedString.addAttribute(.link, value: URL(string: "https://covid19.nhs.uk") as Any, range: range1)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range1)
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: "NHS Link")!, range: range1)

        let range2 = NSRange(fullText.range(of: "privacy policy")!, in: fullText)
        attributedString.addAttribute(.link, value: URL(string: "https://covid19.nhs.uk/data-privacy/app-privacy") as Any, range: range2)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range2)
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: "NHS Link")!, range: range2)

        let range3 = NSRange(fullText.range(of: "terms and conditions")!, in: fullText)
        attributedString.addAttribute(.link, value: URL(string: "https://covid19.nhs.uk/data-privacy/app-terms-conditions") as Any, range: range3)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range3)
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: "NHS Link")!, range: range3)

        readMorePrivacyPolicyAndTermsConditions.attributedText = attributedString
    }
    
    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }

    @IBAction func didTapClose(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
}
