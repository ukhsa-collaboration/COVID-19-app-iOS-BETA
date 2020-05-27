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
        let completion: () -> Void

        init(
            header: String,
            detail: String,
            completion: @escaping () -> Void = {}
        ) {
            self.header = header
            self.detail = detail
            self.completion = completion
        }
    }

    static var storyboardName = "Drawer"

    var config: Config!
    private var headerText: String { config.header }
    private var detailText: String { config.detail }
    private var completion: (() -> Void) { config.completion }

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    func inject(config: Config) {
        self.config = config
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        header.text = headerText
        detail.text = detailText
    }

    @IBAction func closeTapped() {
        performSegue(withIdentifier: "unwindFromDrawer", sender: self)
        completion()
    }

    override func accessibilityPerformEscape() -> Bool {
        closeTapped()
        return true
    }

}
