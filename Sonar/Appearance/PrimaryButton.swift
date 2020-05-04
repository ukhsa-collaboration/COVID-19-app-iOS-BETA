//
//  PrimaryButton.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

//@IBDesignable
class PrimaryButton: ButtonWithDynamicType {

    override var isEnabled: Bool {
        didSet {
            complainIfDisabled()
        }
    }

    override func setUp() {
        super.setUp()
        
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

    private func updateForAccessibility() {
        if UIAccessibility.isInvertColorsEnabled {
            layer.borderColor = UIColor.black.cgColor
            layer.borderWidth = 3
        } else {
            layer.borderWidth = 0
        }
    }

    private func complainIfDisabled() {
        if !isEnabled {
            let msg = "PrimaryButton cannot be disabled. Show an alert instead."
            #if DEBUG
            fatalError(msg)
            #else
            logger.warning(Logger.Message(stringLiteral: msg))
            #endif
        }
    }

}

extension PrimaryButton: UpdatesBasedOnAccessibilityDisplayChanges {
    func updateBasedOnAccessibilityDisplayChanges() {
        updateForAccessibility()
    }
}

private let logger = Logger(label: "PrimaryButton")
