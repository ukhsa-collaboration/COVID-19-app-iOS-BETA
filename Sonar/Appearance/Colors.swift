//
//  Colors.swift
//  Sonar
//
//  Created by NHSX on 03/06/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

extension UIColor {
    private static let grey = (one: UIColor(named: "NHS Grey 1"),
                               two: UIColor(named: "NHS Grey 2"),
                               three: UIColor(named: "NHS Grey 3"),
                               four: UIColor(named: "NHS Grey 4"),
                               five: UIColor(named: "NHS Grey 5"))
    
    static let nhs = (error: UIColor(named: "NHS Error"),
                      button: UIColor(named: "NHS Button"),
                      errorBackground: UIColor(named: "NHS Error Background"),
                      text: UIColor(named: "NHS Text"),
                      secondaryText: UIColor(named: "NHS Secondary Text"),
                      blue: UIColor(named: "NHS Blue"),
                      link: UIColor(named: "NHS Link"),
                      darkBlue: UIColor(named: "NHS Dark Blue"),
                      white: UIColor(named: "NHS White"),
                      highlight: UIColor(named: "NHS Highlight"),
                      grey: grey,
                      errorGrey: UIColor(named: "Error Grey"),
                      warmYellow: UIColor(named: "NHS Warm Yellow"))
}
