//
//  LinkButton.swift
//  Sonar
//
//  Created by NHSX on 04/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LinkButton: ButtonWithDynamicType {

    override func awakeFromNib() {
        super.awakeFromNib()

        guard let title = title(for: .normal) else { return }

        inject(title: title, style: .body)
    }

    func inject(title: String, style: UIFont.TextStyle = .body) {
        accessibilityTraits = .link
        accessibilityHint = "Opens in your browser".localized

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
