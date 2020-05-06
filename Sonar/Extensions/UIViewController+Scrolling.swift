//
//  UIViewController+Scrolling.swift
//  Sonar
//
//  Created by sonar on 5/6/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

extension UIViewController {
    // Scrolls the specified view into view after doing some preparation such as showing the target view.
    // Delays the scrolling until frames have been recalculated, which isn't usually true of naive approaches.
    func scroll(after prepare: @escaping () -> Void, to viewToScrollTo: UIView) {
        // Use UIView.animate to ensure that frames are recalculated before we scroll
        UIView.animate(withDuration: 0, animations: prepare) { finished in
            guard let scrollView = viewToScrollTo.findAncestorScrollView() else {
                logger.warning("Tried to scroll without a UIScrollView ancestor")
                return
            }
            
            let targetRect = viewToScrollTo.convert(viewToScrollTo.bounds, to: scrollView)
            scrollView.scrollRectToVisible(targetRect, animated: true)
        }
    }
}

private func noOp() {
}

private let logger = Logging.Logger(label: "UIViewController+Scrolling")
