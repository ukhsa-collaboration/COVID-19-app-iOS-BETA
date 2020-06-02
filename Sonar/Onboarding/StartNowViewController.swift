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
        resize()
        notificationCenter.addObserver(self, selector: #selector(resize), name: UIApplication.didBecomeActiveNotification, object: nil)
        learnMoreButton.textStyle = .headline
    }
    
    @objc func resize() {
        numberLabels.forEach { numberLabel in
            if let numberView = numberLabel.superview {
                numberView.layer.cornerRadius = numberView.frame.width / 2
                numberView.layer.masksToBounds = true
            }
            numberLabel.textColor = UIColor(named: "NHS White")
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
