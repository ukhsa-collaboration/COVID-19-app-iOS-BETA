//
//  DebuggerTableViewCell.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

final class DebuggerTableViewCell: UITableViewCell {

    let gradientLayer = CAGradientLayer()

    var gradientColorData: Data? {
        didSet {
            gradientLayer.colors = [
                gradientColorData?.asCGColor(alpha: 0) as Any,
                gradientColorData?.asCGColor(alpha: 1) as Any
            ]
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.numberOfLines = 1

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        contentView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        gradientLayer.frame = bounds
    }
}

fileprivate extension Data {
    func asCGColor(alpha: CGFloat) -> CGColor {
        let secondByte = self[1]
        let thirdByte = self[2]
        let fourthByte = self[3]

        let color = UIColor(
            red: CGFloat(secondByte) / 255.0,
            green: CGFloat(thirdByte) / 255.0,
            blue: CGFloat(fourthByte) / 255.0,
            alpha: alpha
        )

        return color.cgColor
    }
}

#endif
