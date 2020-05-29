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
    
    static let darkBlue = UIColor(named: "NHS Dark Blue")!
    static let errorRed = UIColor(named: "NHS Error")!
    
    var hasError: Bool = false {
        didSet {
            updateForCurrentUIStyle()
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateForCurrentUIStyle()
    }
    
    private func commonInit() {
        addTarget(self, action: #selector(updateForCurrentUIStyle), for: .allEditingEvents)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        updateForCurrentUIStyle()
    }
    
    @objc private func updateForCurrentUIStyle() {
        switch (isEditing, hasError) {
        case (false, false):
            layer.borderWidth = 1
            layer.borderColor = UIColor.black.cgColor
        case (true, false):
            layer.borderWidth = 3
            layer.borderColor = Self.darkBlue.cgColor
        case (_, true):
            layer.borderColor = Self.errorRed.cgColor
            layer.borderWidth = 3
        }
    }
}
