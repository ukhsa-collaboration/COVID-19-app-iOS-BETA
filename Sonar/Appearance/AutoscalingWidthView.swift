//
//  AutoscalingWidthView.swift
//  Sonar
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AutoscalingWidthView: UIView, UpdatesBasedOnAccessibilityDisplayChanges {
    private var widthConstraint: NSLayoutConstraint!
    private var scaleFactor: CGFloat!
    
    override func awakeFromNib() {
        scaleFactor = bounds.size.width / FontScaling.bodyFontDefaultSize
        widthConstraint = widthAnchor.constraint(equalToConstant: bounds.size.width)
        NSLayoutConstraint.activate([widthConstraint])
        
        updateBasedOnAccessibilityDisplayChanges()
    }

    func updateBasedOnAccessibilityDisplayChanges() {
        widthConstraint.constant = scaleFactor * FontScaling.bodyFontDefaultSize * FontScaling.currentFontSizeMultiplier()
    }

}
