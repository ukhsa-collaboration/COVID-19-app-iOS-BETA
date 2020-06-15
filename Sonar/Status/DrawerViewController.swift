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
    private var callToAction: (title: String, action: () -> Void)?
    private var completion: (() -> Void)!

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var primaryButton: PrimaryButton!

    func inject(
        header: String,
        detail: String,
        callToAction: (title: String, action: () -> Void)? = nil,
        completion: @escaping () -> Void
    ) {
        self.header = header
        self.detail = detail
        self.callToAction = callToAction
        self.completion = completion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        headerLabel.text = header
        detailLabel.text = detail

        if let (title, _) = callToAction {
            primaryButton.setTitle(title, for: .normal)
            primaryButton.isHidden = false
        }
    }

    @IBAction func primaryButtonTapped() {
        closeTapped()

        if let (_, action) = callToAction {
            action()
        }
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
