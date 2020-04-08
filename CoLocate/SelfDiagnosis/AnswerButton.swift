//
//  AnswerButton.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AnswerButton: UIButton {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }

    override func awakeFromNib() {
        layer.cornerRadius = 10

        backgroundColor = UIColor(named: "NHS White")
        setTitleColor(UIColor(named: "NHS Text"), for: .normal)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)

        setImage(UIImage(named: "Controls_RadioButton_Unselected"), for: .normal)
        setImage(UIImage(named: "Controls_RadioButton_Selected"), for: .selected)

        contentHorizontalAlignment = .left
        contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        titleEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        titleLabel?.numberOfLines = 0
    }
}
