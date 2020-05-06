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
        detailTextLabel?.numberOfLines = 1

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        contentView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        gradientLayer.frame = bounds
    }
}

extension Data {
    
    func asCGColor(alpha: CGFloat) -> CGColor {
        return asUIColor(alpha: alpha).cgColor
    }

    func asUIColor(alpha: CGFloat) -> UIColor {
        guard self.count >= 3 else {
            return UIColor.white
        }
        return UIColor(red: CGFloat(self[0]) / 255.0, green: CGFloat(self[1]) / 255.0, blue: CGFloat(self[2]) / 255.0, alpha: alpha)
    }

}

#endif
