//
//  Appearance.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

enum Appearance {}
extension Appearance {
    static func setup() {
        UILabel.appearance().textColor = UIColor(named: "NHS Text")
        UILabel.appearance().adjustsFontForContentSizeCategory = true
        UILabel.appearance().numberOfLines = 0

        UILabel.appearance(whenContainedInInstancesOf: [LogoStrapline.self]).textColor = UIColor(named: "NHS White")
    }
}
