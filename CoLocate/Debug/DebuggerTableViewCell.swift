//
//  DebuggerTableViewCell.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DebuggerTableViewCell: UITableViewCell {

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

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        contentView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        gradientLayer.frame = bounds
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
