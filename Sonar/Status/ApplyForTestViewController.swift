//
//  ApplyForTestViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ApplyForTestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = {
            let title = UILabel()
            title.text = "Apply for a coronavirus test"
            title.textColor = UIColor(named: "NHS Blue")
            title.font = UIFont.preferredFont(forTextStyle: .headline)
            return title
        }()
    }

    @IBAction func applyForTestTapped(_ sender: UIButton) {
        let url = URL(string: "https://self-referral.test-for-coronavirus.service.gov.uk/cta-start?ctaToken=token-value")!
        UIApplication.shared.open(url)
    }

}
