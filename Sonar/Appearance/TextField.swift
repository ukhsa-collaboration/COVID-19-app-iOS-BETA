//
//  TextField.swift
//  Sonar
//
//  Created by NHSX on 4/15/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

// A UITextField that uses different border colors for light and dark mode.
// For most UI elements we'd create a color asset with separate light and dark
// colors, but layers don't appear to change their colors when the UI style
// changes after initial rendering.
class TextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateForCurrentUIStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateForCurrentUIStyle()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateForCurrentUIStyle()
    }
    
    private func updateForCurrentUIStyle() {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        layer.borderWidth = 1
        
        if inDarkMode() {
            layer.borderColor = UIColor.white.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
    }
    
    private func inDarkMode() -> Bool {
        if #available(iOS 12.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }
}
