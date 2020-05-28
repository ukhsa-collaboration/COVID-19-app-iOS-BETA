//
//  DrawerViewController.swift
//  Sonar
//
//  Created by NHSX on 20/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DrawerViewController: UIViewController, Storyboarded {
    static var storyboardName = "Drawer"

    var header: String!
    private var detail: String!
    private var completion: (() -> Void)!

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    func inject(header: String, detail: String, completion: @escaping () -> Void) {
        self.header = header
        self.detail = detail
        self.completion = completion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = header
        detailLabel.text = detail
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
