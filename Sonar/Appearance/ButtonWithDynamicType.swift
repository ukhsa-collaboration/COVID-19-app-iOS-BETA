//
//  ButtonWithDynamicType.swift
//  Sonar
//
//  Created by NHSX on 4/13/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

// Note: Also need to set the font to "body" (probably in Interface Builder) as well as using this class.
class ButtonWithDynamicType: UIButton {

    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel?.intrinsicContentSize ?? CGSize.zero
        return CGSize(width: titleSize.width, height: max(titleSize.height + 16, 54))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUp()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setUp()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
        super.layoutSubviews()
    }

    internal func setUp() {
        guard let titleLabel = titleLabel else { return }
        
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
    }

}
