//
//  SmartInvertBorderView.swift
//  Sonar
//
//  Created by NHSX on 5/6/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SmartInvertBorderView: UIView {
    
    let notificationCenter = NotificationCenter.default

    override func awakeFromNib() {
        super.awakeFromNib()
        notificationCenter.addObserver(self, selector: #selector(updateBasedOnAccessibilityDisplayChanges), name: UIApplication.didBecomeActiveNotification, object: nil)
        updateBasedOnAccessibilityDisplayChanges()
    }
}

extension SmartInvertBorderView: UpdatesBasedOnAccessibilityDisplayChanges {
    @objc func updateBasedOnAccessibilityDisplayChanges() {
        if UIAccessibility.isInvertColorsEnabled {
            layer.borderColor = UIColor.black.cgColor
            layer.borderWidth = 3
        } else {
            layer.borderWidth = 0
        }
    }
}
