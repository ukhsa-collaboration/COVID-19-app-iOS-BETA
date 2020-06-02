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
    
    // Depending on exactly how the button is used, the title may be set by calling
    // setTitle(for state:) or by setting the titleLabel's text directly.
    // We need to style the text appropriately in either case.
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        guard let title = title, state == .normal else { return }
        
        accessibilityLabel = title
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: attributes()
        )
        setAttributedTitle(attributedTitle, for: .normal)
    }


    private func update() {
        guard let title = titleLabel?.text else { return }

        accessibilityLabel = title
        titleLabel?.attributedText = NSAttributedString(
            string: title,
            attributes: attributes()
        )
    }
    
    private func attributes() -> [NSAttributedString.Key : Any] {
        return [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: buttonDefaultColor,
            .font: UIFont.preferredFont(forTextStyle: textStyle)
        ]
    }

}
