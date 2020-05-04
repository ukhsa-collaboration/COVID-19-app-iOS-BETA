//
//  AccessibleErrorLabel.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AccessibleErrorLabel : UILabel {
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
