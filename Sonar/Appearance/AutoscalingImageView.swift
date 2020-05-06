//
//  AutoscalingImageView.swift
//  Sonar
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//@IBDesignable
class AutoscalingImageView: UIImageView, UpdatesBasedOnAccessibilityDisplayChanges {
    private var widthConstraint: NSLayoutConstraint!
    private var scaleFactor: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        scaleFactor = bounds.size.width / FontScaling.bodyFontDefaultSize
        widthConstraint = widthAnchor.constraint(equalToConstant: bounds.size.width)
        let aspectRatioConstraint = NSLayoutConstraint(
            item: self,
            attribute: .height,
            relatedBy: .equal,
            toItem: self,
            attribute: .width,
            multiplier: bounds.size.height / bounds.size.width,
            constant: 0
        )
        NSLayoutConstraint.activate([widthConstraint, aspectRatioConstraint])
        
        updateBasedOnAccessibilityDisplayChanges()
    }

    func updateBasedOnAccessibilityDisplayChanges() {
        widthConstraint.constant = scaleFactor * FontScaling.bodyFontDefaultSize * FontScaling.currentFontSizeMultiplier()
    }
}
