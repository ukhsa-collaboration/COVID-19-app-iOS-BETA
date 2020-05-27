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
    private var url: URL!
    
    func inject(linkDestination: URL) {
        url = linkDestination
    }
    
    override func viewDidLoad() {
        link.textStyle = .headline
        link.url = url

        detail.text = "The advice below is up to date and specific to your situation. Please follow this advice."
    }
}
