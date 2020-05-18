//
//  WorkplaceGuidanceViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class WorkplaceGuidanceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = {
            let title = UILabel()
            title.text = "Guidance for your workplace"
            title.textColor = UIColor(named: "NHS Blue")
            title.font = UIFont.preferredFont(forTextStyle: .headline)
            return title
        }()
    }

    @IBAction func linkTapped(_ sender: UIButton) {
        UIApplication.shared.open(ContentURLs.shared.workplaceGuidance)
    }

}
