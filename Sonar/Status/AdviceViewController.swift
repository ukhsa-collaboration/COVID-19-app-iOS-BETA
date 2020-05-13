//
//  AdviceViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AdviceViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"
    private let content = StatusContent.shared

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var link: LinkButton!
    
    @IBAction func linkTap(_ sender: Any) {

    }
}
