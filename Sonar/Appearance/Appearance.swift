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
            NSAttributedString.Key.foregroundColor: UIColor.nhs.blue,
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline),
        ]
        UINavigationBar.appearance().tintColor = UIColor.nhs.blue

        UILabel.appearance().textColor = UIColor.nhs.text
        UILabel.appearance().adjustsFontForContentSizeCategory = true
        UILabel.appearance().numberOfLines = 0

        UILabel.appearance(whenContainedInInstancesOf: [LinkButton.self]).textColor = UIColor.nhs.link
    }
}
