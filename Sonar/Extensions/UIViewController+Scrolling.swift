//
//  UIViewController+Scrolling.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

extension UIViewController {
    // Scrolls the specified view into view after doing some preparation such as showing the target view.
    // Delays the scrolling until frames have been recalculated, which isn't usually true of naive approaches.
    func scroll(after prepare: @escaping () -> Void, to viewToScrollTo: UIView) {
        scroll(after: prepare, to: { viewToScrollTo })
    }
    
    func scroll(after prepare: @escaping () -> Void, to getViewToScrollTo: @escaping () -> UIView) {
        // Use UIView.animate to ensure that frames are recalculated before we scroll
        UIView.animate(withDuration: 0, animations: prepare) { finished in
            let viewToScrollTo = getViewToScrollTo()
            guard let scrollView = viewToScrollTo.findAncestorScrollView() else {
                logger.warning("Tried to scroll without a UIScrollView ancestor")
                return
            }
            
            let targetRect = viewToScrollTo.convert(viewToScrollTo.bounds, to: scrollView)
            scrollView.scrollRectToVisible(targetRect, animated: true)
        }
    }
    
    // Scrolls so that both the error label and the control will be in view if possible,
    // otherwise scrolls the error label into view.
    // Assumes that the error label is above the field.
    func scroll(after prepare: @escaping () -> Void, toErrorLabel errorLabel: AccessibleErrorLabel, orControl control: UIControl) {
        guard let scrollView = errorLabel.findAncestorScrollView() else {
            logger.warning("Tried to scroll without a UIScrollView ancestor")
            return
        }
        
        scroll(after: prepare, to: { () -> UIView in
            return scrollTarget(errorLabel: errorLabel, orControl: control, inScrollView: scrollView)
        })
    }
}

private func scrollTarget(
    errorLabel: AccessibleErrorLabel,
    orControl control: UIControl,
    inScrollView scrollView: UIScrollView
) -> UIView {
    // Choose the field if they'll both fit, otherwise the error label.
    let adjustedFieldFrame = control.convert(control.bounds, to: errorLabel)
    let desiredHeight = adjustedFieldFrame.size.height + adjustedFieldFrame.origin.y
    let availableHeight = scrollView.bounds.height - scrollView.contentInset.bottom - scrollView.contentInset.top
    
    if desiredHeight < availableHeight {
        return control
    } else {
        return errorLabel
    }
}

private func noOp() {
}

private let logger = Logging.Logger(label: "UIViewController+Scrolling")
