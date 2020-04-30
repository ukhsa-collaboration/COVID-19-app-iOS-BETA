//
//  StartNowViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StartNowViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var persistence: Persisting! = nil
    private var notificationCenter: NotificationCenter! = nil
    private var continueHandler: (() -> Void)! = nil
    
    @IBOutlet weak var howItWorks: ButtonWithDynamicType!

    override func viewDidLoad() {
        super.viewDidLoad()

        howItWorks.setAttributedTitle(NSAttributedString(string: "Learn more about how it works".localized, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor(named: "NHS Link")]), for: .normal)
    }

    func inject(persistence: Persisting, notificationCenter: NotificationCenter, continueHandler: @escaping () -> Void) {
        self.persistence = persistence
        self.notificationCenter = notificationCenter
        self.continueHandler = continueHandler
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destination = segue.destination as? PostcodeViewController {
            destination.inject(persistence: persistence,
                               notificationCenter: notificationCenter,
                               continueHandler: continueHandler)
        }
    }
}
