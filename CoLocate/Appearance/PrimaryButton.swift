//
//  PrimaryButton.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//@IBDesignable
class PrimaryButton: ButtonWithDynamicType {

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.3
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

        alpha = isEnabled ? 1.0 : 0.3
    }

}
