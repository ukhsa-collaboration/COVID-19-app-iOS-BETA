//
//  ApplyForTestViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ApplyForTestViewController: UIViewController {
    
    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!

    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
    }

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: uiQueue)
        }
    }

    @IBAction func applyForTestTapped(_ sender: UIButton) {
        let url = URL(string: "https://self-referral.test-for-coronavirus.service.gov.uk/cta-start?ctaToken=token-value")!
        UIApplication.shared.open(url)
    }

}
