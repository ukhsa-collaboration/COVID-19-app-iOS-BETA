//
//  ErrorView.swift
//  Sonar
//
//  Created by NHSX on 25/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

private struct Colors {
    var background: UIColor
    var headerText: UIColor
    var bodyText: UIColor
    var stripe: UIColor
}

private let errorBackgroundColor = UIColor(named: "NHS Error Background")!
private let errorColor = UIColor(named: "NHS Error")!

private let normalColors = Colors(
    background: errorBackgroundColor,
    headerText: UIColor(named: "NHS Text")!,
    bodyText: errorColor,
    stripe: errorColor
)

private let smartInvertColors = Colors(
    background: .black,
    headerText: .white,
    bodyText: errorBackgroundColor,
    stripe: errorBackgroundColor
)

class ErrorView: IBView, UpdatesBasedOnAccessibilityDisplayChanges {
    
    @IBOutlet weak var title: UILabel! 
    @IBOutlet weak var errorMessage: AccessibleErrorLabel!
    @IBOutlet var stripe: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // We'll apply our own colors when Smart Invert is on.
        // Stop iOS from trying to do it for us.
        for view in [self, title, errorMessage, stripe] {
            view!.accessibilityIgnoresInvertColors = true
        }
        
        updateBasedOnAccessibilityDisplayChanges()
    }
    
    override var isHidden: Bool {
        didSet {
            guard isHidden == false else { return }
            
            UIAccessibility.post(notification: .screenChanged,
                                 argument: self)
        }
    }
    
    func updateBasedOnAccessibilityDisplayChanges() {
        let colors = currentColorScheme()
        backgroundColor = colors.background
        title.textColor = colors.headerText
        errorMessage.textColor = colors.bodyText
        stripe.backgroundColor = colors.stripe
    }
        
    private func currentColorScheme() -> Colors {
        if UIAccessibility.isInvertColorsEnabled {
            return smartInvertColors
        } else {
            return normalColors
        }
    }
    
}
