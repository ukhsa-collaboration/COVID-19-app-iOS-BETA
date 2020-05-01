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

    @IBOutlet weak var moreAbout: ButtonWithDynamicType!
    @IBOutlet weak var privacyPolicy: ButtonWithDynamicType!
    @IBOutlet weak var termsConditions: ButtonWithDynamicType!
    
    override func viewDidLoad() {
        moreAbout.setAttributedTitle(NSAttributedString(string: "More about the app".localized, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor(named: "NHS Link")!]), for: .normal)
        moreAbout.accessibilityTraits = .link

        
        privacyPolicy.setAttributedTitle(NSAttributedString(string: "Privacy policy".localized, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor(named: "NHS Link")!]), for: .normal)
        privacyPolicy.accessibilityTraits = .link
        
        termsConditions.setAttributedTitle(NSAttributedString(string: "Terms and conditions".localized, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor(named: "NHS Link")!]), for: .normal)
        termsConditions.accessibilityTraits = .link
    }
    
    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }
    
    @IBAction func tapMoreAbout(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://covid19.nhs.uk")!)
    }
    
    @IBAction func tapPrivacy(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://covid19.nhs.uk/data-privacy/app-privacy")!)
    }
    
    @IBAction func tapTerms(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://covid19.nhs.uk/data-privacy/app-terms-conditions")!)
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
}
