//
//  WorkplaceGuidanceViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class WorkplaceGuidanceViewController: UIViewController {

    @IBAction func linkTapped(_ sender: UIButton) {
        UIApplication.shared.open(ContentURLs.shared.workplaceGuidance)
    }

}
