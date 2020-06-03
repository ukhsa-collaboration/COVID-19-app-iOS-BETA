//
//  DebuggerTableViewCell.swift
//  Sonar
//
//  Created by NHSX on 02.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

final class GradientBackgroundTableViewCell: UITableViewCell {

    let gradientLayer = CAGradientLayer()

    var gradientColorData: Data? {
        didSet {
            gradientLayer.colors = [
                gradientColorData?.asCGColor(alpha: 0) ?? UIColor.clear.cgColor,
                gradientColorData?.asCGColor(alpha: 1) ?? UIColor.clear.cgColor
            ]
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.numberOfLines = 1
        detailTextLabel?.numberOfLines = 1

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        layer.insertSublayer(gradientLayer, at: 0)
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
        // These need to be copies so we don't hang on to a reference to the original data and crash later
        let r = self[0]
        let g = self[1]
        let b = self[2]
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }

}

#endif
