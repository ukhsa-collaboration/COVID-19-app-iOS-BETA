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
    private var close: String!
    var callToAction: (title: String, action: () -> Void)?
    private var closeCompletion: (() -> Void)!

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var primaryButton: PrimaryButton!
    @IBOutlet weak var closeButton: ButtonWithDynamicType!

    func inject(
        header: String,
        detail: String,
        close: String,
        callToAction: (title: String, action: () -> Void)? = nil,
        closeCompletion: @escaping () -> Void
    ) {
        self.header = header
        self.detail = detail
        self.close = close
        self.callToAction = callToAction
        self.closeCompletion = closeCompletion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        headerLabel.text = header
        detailLabel.text = detail
        closeButton.setTitle(close, for: .normal)

        if let (title, _) = callToAction {
            primaryButton.setTitle(title, for: .normal)
            primaryButton.isHidden = false
        }
    }

    @IBAction func primaryButtonTapped() {
        performSegue(withIdentifier: "unwindFromDrawer", sender: self)

        if let (_, action) = callToAction {
            action()
        }
    }

    @IBAction func closeTapped() {
        performSegue(withIdentifier: "unwindFromDrawer", sender: self)

        closeCompletion()
    }

    override func accessibilityPerformEscape() -> Bool {
        closeTapped()
        return true
    }

}
