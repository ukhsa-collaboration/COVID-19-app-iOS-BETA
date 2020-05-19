//
//  NotificationStatusButton.swift
//  Sonar
//
//  Created by NHSX on 17.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

//@IBDesignable
class NotificationStatusButton: ButtonWithDynamicType {
    override func setUp() {
        super.setUp()
        
        layer.cornerRadius = 8
        clipsToBounds = true
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel?.textAlignment = .center

        alpha = 1.0

        updateForAccessibility()
    }

    @objc private func updateForAccessibility() {
        if UIAccessibility.isInvertColorsEnabled {
            layer.borderColor = UIColor.black.cgColor
            layer.borderWidth = 3
        } else {
            layer.borderWidth = 0
        }
    }
}

extension NotificationStatusButton: UpdatesBasedOnAccessibilityDisplayChanges {
    func updateBasedOnAccessibilityDisplayChanges() {
        updateForAccessibility()
    }
}
