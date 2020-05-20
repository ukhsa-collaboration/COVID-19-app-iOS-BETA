//
//  Appearance.swift
//  Sonar
//
//  Created by NHSX on 4/9/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

enum Appearance {}
extension Appearance {
    static func setup() {
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "NHS Blue")!,
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline),
        ]

        UILabel.appearance().textColor = UIColor(named: "NHS Text")
        UILabel.appearance().adjustsFontForContentSizeCategory = true
        UILabel.appearance().numberOfLines = 0

        ErrorLabel.appearance().textColor = UIColor(named: "NHS Error")
        ErrorLabel.appearance().font = UIFont.preferredFont(forTextStyle: .callout)
        ErrorLabel.appearance().adjustsFontForContentSizeCategory = true
        ErrorLabel.appearance().numberOfLines = 0

        AccessibleErrorLabel.appearance().textColor = UIColor(named: "NHS Error")
        AccessibleErrorLabel.appearance().font = UIFont.preferredFont(forTextStyle: .callout)
        AccessibleErrorLabel.appearance().adjustsFontForContentSizeCategory = true
        AccessibleErrorLabel.appearance().numberOfLines = 0

        UILabel.appearance(whenContainedInInstancesOf: [LinkButton.self]).textColor = UIColor(named: "NHS Link")
    }
}
