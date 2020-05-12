//
//  SmartInvertBorderView.swift
//  Sonar
//
//  Created by NHSX on 5/6/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SmartInvertBorderView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()

        updateBasedOnAccessibilityDisplayChanges()
    }
}

extension SmartInvertBorderView: UpdatesBasedOnAccessibilityDisplayChanges {
    func updateBasedOnAccessibilityDisplayChanges() {
        if UIAccessibility.isInvertColorsEnabled {
            layer.borderColor = UIColor.black.cgColor
            layer.borderWidth = 3
        } else {
            layer.borderWidth = 0
        }
    }
}
