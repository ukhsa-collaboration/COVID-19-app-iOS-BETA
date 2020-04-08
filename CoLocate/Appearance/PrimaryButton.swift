//
//  PrimaryButton.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//@IBDesignable
class PrimaryButton: UIButton {

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.3
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 54.0)
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
    
    private func setUp() {
        layer.cornerRadius = 10
        clipsToBounds = true
        backgroundColor = UIColor(named: "NHS Button")
        setTitleColor(.white, for: .normal)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel?.textAlignment = .center

        alpha = isEnabled ? 1.0 : 0.3
    }

}
