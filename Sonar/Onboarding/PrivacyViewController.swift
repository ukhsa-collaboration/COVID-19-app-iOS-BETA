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

    func inject(continueHandler: @escaping () -> Void) {
        self.continueHandler = continueHandler
    }

    override func viewDidLoad() {
        moreAbout.url = ContentURLs.shared.moreAbout
        privacyPolicy.url = ContentURLs.shared.privacyAndData
        termsConditions.url = ContentURLs.shared.ourPolicies
    }

    @IBAction func didTapClose(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
}
