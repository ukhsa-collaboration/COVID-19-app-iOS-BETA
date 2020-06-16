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

private let normalColors = Colors(
    background: UIColor.nhs.errorBackground!,
    headerText: UIColor.nhs.text!,
    bodyText: UIColor.nhs.error!,
    stripe: UIColor.nhs.error!
)

private let smartInvertColors = Colors(
    background: .black,
    headerText: .white,
    bodyText: UIColor.nhs.errorBackground!,
    stripe: UIColor.nhs.errorBackground!
)

class ErrorView: IBView, UpdatesBasedOnAccessibilityDisplayChanges {
    
    @IBOutlet weak var title: UILabel! 
    @IBOutlet weak var errorMessage: AccessibleErrorLabel!
    @IBOutlet var stripe: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        isAccessibilityElement = true
        accessibilityElements = [title!, errorMessage!]
        accessibilityLabel = "\(title!.text!). \(errorMessage!.text!)"

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

            // Update this here since these can be dynamically set.
            accessibilityLabel = [title?.text, errorMessage?.text].compactMap { $0 }.joined(separator: ". ")

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
