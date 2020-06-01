//
//  UnderlinedBarButtonItem.swift
//  Sonar
//
//  Created by NHSX on 6/1/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

private let navBarDefaultColor = UIColor(red: 0, green: 0.37, blue: 0.72, alpha: 1)

class UnderlinedBarButtonItem: UIBarButtonItem {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setTitleTextAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: navBarDefaultColor
        ], for: .normal)
    }
}
