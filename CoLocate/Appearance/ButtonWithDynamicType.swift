//
//  ButtonWithDynamicType.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

// Note: Also need to set the font to "body" (probably in Interface Builder) as well as using this class.
class ButtonWithDynamicType: UIButton {
    
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
    
    internal func setUp() {
        guard let titleLabel = titleLabel else { return }
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 54.0),
            NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 8)
        ])
        
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
    }
}
