//
//  LinkButton.swift
//  Sonar
//
//  Created by NHSX on 04/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LinkButton: ButtonWithDynamicType {

    @IBInspectable var isExternal: Bool = false {
        didSet {
            if isExternal {
                accessibilityTraits = .link
                accessibilityHint = "Opens in your browser".localized
            } else {
                accessibilityTraits = .button
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        guard let title = title(for: .normal) else { return }

        inject(title: title, isExternal: isExternal, style: .body)
    }

    func inject(title: String, isExternal: Bool? = nil, style: UIFont.TextStyle) {
        if let isExternal = isExternal {
            self.isExternal = isExternal
        }

        titleLabel?.attributedText = NSAttributedString(string: title, attributes:
            [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor(named: "NHS Link")!,
                .font: UIFont.preferredFont(forTextStyle: style)
            ]
        )
        setTitle(title, for: .normal)
    }

}
