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

    @IBOutlet weak var moreAbout: LinkButton!
    @IBOutlet weak var privacyPolicy: LinkButton!
    @IBOutlet weak var termsConditions: LinkButton!
    
    override func viewDidLoad() {
        moreAbout.inject(title: "More about the app".localized)
        privacyPolicy.inject(title: "Privacy notice".localized)
        termsConditions.inject(title: "Terms of use".localized)
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
