//
//  DrawerViewController.swift
//  Sonar
//
//  Created by NHSX on 20/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DrawerViewController: UIViewController, Storyboarded {

    struct Config {
        let header: String
        let detail: String
    }

    static var storyboardName = "Drawer"
    
    private var headerText: String?
    private var detailText: String?

    @IBOutlet private weak var header: UILabel!
    @IBOutlet private weak var detail: UILabel!
    
    func inject(config: Config) {
        self.headerText = config.header
        self.detailText = config.detail
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        header.text = headerText
        detail.text = detailText
    }

    override func accessibilityPerformEscape() -> Bool {
        performSegue(withIdentifier: "unwindFromDrawer", sender: self)
        return true
    }

}
