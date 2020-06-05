//
//  StartNowViewController.swift
//  Sonar
//
//  Created by NHSX on 3/31/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StartNowViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var persistence: Persisting! = nil
    private var notificationCenter: NotificationCenter! = nil
    private var continueHandler: (() -> Void)! = nil
    
    @IBOutlet weak var learnMoreButton: UnderlinedButton!
    @IBOutlet var numberLabels: [UILabel]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        learnMoreButton.textStyle = .headline
        
        numberLabels.forEach { numberLabel in
            if let numberView = numberLabel.superview {
                numberView.layer.masksToBounds = true
            }
            numberLabel.textColor = UIColor(named: "NHS White")
        }
    }
    
    override func viewWillLayoutSubviews() {
        numberLabels.forEach { numberLabel in
            if let numberView = numberLabel.superview {
                numberView.layer.cornerRadius = numberView.frame.width / 2
            }
        }
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
