//
//  AccessibleErrorLabel.swift
//  Sonar
//
//  Created by NHSX on 02/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AccessibleErrorLabel : UILabel {
    override func awakeFromNib() {
        textColor = UIColor(named: "NHS Error")
        font = UIFont.preferredFont(forTextStyle: .callout)
        adjustsFontSizeToFitWidth = true
        numberOfLines = 0
    }
    
    override var isHidden: Bool {
        didSet {
            guard isHidden == false else { return }

            postVoiceOverNotification()
        }
    }

    private func postVoiceOverNotification() {
        UIAccessibility.post(notification: .screenChanged,
                             argument: self)
    }
}
