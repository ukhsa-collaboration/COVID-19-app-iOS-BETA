//
//  SelfsizingTextView.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SelfsizingTextView : UITextView {
    override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: bounds.size.width, height: 1_000))
    }
    
    override var bounds: CGRect {
        get {
            super.bounds
        }
        set {
            if newValue.size.width != bounds.size.width {
                invalidateIntrinsicContentSize()
            }
            super.bounds = newValue
        }
    }
}
