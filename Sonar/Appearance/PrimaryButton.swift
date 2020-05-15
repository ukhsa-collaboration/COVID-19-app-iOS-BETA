//
//  PrimaryButton.swift
//  Sonar
//
//  Created by NHSX on 17.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

//@IBDesignable
class PrimaryButton: ButtonWithDynamicType {
    
    let notificationCenter = NotificationCenter.default
    
    override var isEnabled: Bool {
        didSet {
            complainIfDisabled()
        }
    }

    override func setUp() {
        super.setUp()
        
        notificationCenter.addObserver(self, selector: #selector(updateForAccessibility), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = UIColor(named: "NHS Button")
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel?.textAlignment = .center

        alpha = 1.0

        updateForAccessibility()

        complainIfDisabled()
    }

    @objc private func updateForAccessibility() {
        if UIAccessibility.isInvertColorsEnabled {
            layer.borderColor = UIColor.black.cgColor
            layer.borderWidth = 3
        } else {
            layer.borderWidth = 0
        }
    }

    private func complainIfDisabled() {
        if !isEnabled {
            assertionFailure("PrimaryButton cannot be disabled. Show an alert instead.")
        }
    }

}

extension PrimaryButton: UpdatesBasedOnAccessibilityDisplayChanges {
    func updateBasedOnAccessibilityDisplayChanges() {
        updateForAccessibility()
    }
}

private let logger = Logger(label: "PrimaryButton")
