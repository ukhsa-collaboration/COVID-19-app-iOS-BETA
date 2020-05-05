//
//  UpdatesBasedOnAccessibilityDisplayChanges.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol UpdatesBasedOnAccessibilityDisplayChanges {
    func updateBasedOnAccessibilityDisplayChanges()
}

class FontScaling {
    static let bodyFontDefaultSize = CGFloat(17.0)
    
    static func currentFontSizeMultiplier() -> CGFloat {
        return CGFloat(UIFont.preferredFont(forTextStyle: .body).pointSize) / bodyFontDefaultSize
    }
}
