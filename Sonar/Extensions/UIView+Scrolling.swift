//
//  UIView+Scrolling.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

extension UIView {
    func findAncestorScrollView() -> UIScrollView? {
        if let scrollView = superview as? UIScrollView {
            return scrollView
        } else {
            return superview?.findAncestorScrollView()
        }
    }
}
