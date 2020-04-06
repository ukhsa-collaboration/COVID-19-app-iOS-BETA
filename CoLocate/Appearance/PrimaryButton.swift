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

    private let disabledColorImage: UIImage? = {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor(named: "NHS Grey 2")!.cgColor)
        context?.fill(rect)

        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()

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
        layer.cornerRadius = 4
        clipsToBounds = true
        backgroundColor = UIColor(named: "NHS Button")
        setTitleColor(.white, for: .normal)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        setBackgroundImage(disabledColorImage, for: .disabled)
    }

}
