//
//  PrivacyViewController.swift
//  Sonar
//
//  Created by NHSX on 3/31/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PrivacyViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var continueHandler: (() -> Void)! = nil

    @IBOutlet weak var moreAbout: LinkButton!
    @IBOutlet weak var privacyPolicy: LinkButton!
    @IBOutlet weak var termsConditions: LinkButton!
    
    override func viewDidLoad() {
        moreAbout.inject(title: "More about the app".localized, isExternal: true, style: .body)
        privacyPolicy.inject(title: "Privacy notice".localized, isExternal: true, style: .body)
        termsConditions.inject(title: "Terms of use".localized, isExternal: true, style: .body)
    }
    
    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }
    
    @IBAction func tapMoreAbout(_ sender: Any) {
        UIApplication.shared.open(ContentURLs.shared.moreAbout)
    }
    
    @IBAction func tapPrivacy(_ sender: Any) {
        UIApplication.shared.open(ContentURLs.shared.privacyAndData)
    }
    
    @IBAction func tapTerms(_ sender: Any) {
        UIApplication.shared.open(ContentURLs.shared.ourPolicies)
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
}
