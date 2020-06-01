//
//  UnderlinedButton.swift
//  Sonar
//
//  Created by NHSX on 6/1/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//@IBDesignable
class UnderlinedButton: UIButton {

    var textStyle: UIFont.TextStyle = .body {
        didSet { update() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        update()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        update()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        update()
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        update()
    }


    private func update() {
        guard let title = titleLabel?.text else { return }

        accessibilityLabel = title
        titleLabel?.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.preferredFont(forTextStyle: textStyle)
            ]
        )
    }

}
