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
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func accessibilityPerformEscape() -> Bool {
        close(self)
        return true
    }
    
    private var headerText: String?
    private var detailText: String?

    @IBOutlet private weak var header: UILabel!
    @IBOutlet private weak var detail: UILabel!
    
    func inject(headerText: String?, detailText: String) {
        self.headerText = headerText
        self.detailText = detailText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        header.text = headerText
        detail.text = detailText
    }
}
