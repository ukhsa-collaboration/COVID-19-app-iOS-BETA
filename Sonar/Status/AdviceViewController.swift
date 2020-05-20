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
    
    var linkDestination: URL!
    func inject(linkDestination: URL) {
        self.linkDestination = linkDestination
    }
    
    @IBAction func linkTap(_ sender: Any) {
        UIApplication.shared.open(linkDestination)
    }
    
    override func viewDidLoad() {
        link.inject(title: "Read specific advice on GOV.UK", style: .headline)
        
        detail.text = "The advice below is up to date and specific to your situation. Please follow this advice."
    }
}
