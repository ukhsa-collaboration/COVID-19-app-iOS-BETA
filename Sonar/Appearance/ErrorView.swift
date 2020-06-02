//
//  ErrorView.swift
//  Sonar
//
//  Created by NHSX on 25/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit


class ErrorView: IBView {
    
    @IBOutlet weak var title: UILabel! 
    @IBOutlet weak var errorMessage: AccessibleErrorLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        errorMessage.textColor = UIColor(named: "NHS Error")
    }
    
    override var isHidden: Bool {
        didSet {
            guard isHidden == false else { return }

            UIAccessibility.post(notification: .screenChanged,
                                 argument: self)
        }
    }

}
