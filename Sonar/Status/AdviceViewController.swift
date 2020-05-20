//
//  AdviceViewController.swift
//  Sonar
//
//  Created by NHSX on 12/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AdviceViewController: UIViewController, Storyboarded {
    static let storyboardName = "Advice"

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var link: LinkButton!
    
    func inject(linkDestination: URL) {
        link.url = linkDestination
    }
    
    override func viewDidLoad() {
        link.textStyle = .headline

        detail.text = "The advice below is up to date and specific to your situation. Please follow this advice."
    }
}
