//
//  LinkButton.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LinkButton: ButtonWithDynamicType {
    func inject(title: String) {
        accessibilityHint = "Opens in your browser".localized
        accessibilityTraits = .link
        setAttributedTitle(NSAttributedString(string: title, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor(named: "NHS Link")!]), for: .normal)
    }
}
