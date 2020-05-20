//
//  WorkplaceGuidanceViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class WorkplaceGuidanceViewController: UIViewController {

    @IBOutlet weak var linkButton: LinkButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        linkButton.url = ContentURLs.shared.workplaceGuidance
    }

}
