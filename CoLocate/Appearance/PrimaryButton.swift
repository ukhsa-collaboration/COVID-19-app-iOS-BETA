//
//  PrimaryButton.swift
//  CoLocate
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
        
        layer.cornerRadius = 10
        clipsToBounds = true
        backgroundColor = UIColor(named: "NHS Button")
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel?.textAlignment = .center

        alpha = 1.0
        
        complainIfDisabled()
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

private let logger = Logger(label: "PrimaryButton")
