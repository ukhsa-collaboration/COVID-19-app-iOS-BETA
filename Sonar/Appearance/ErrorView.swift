//
//  ErrorView.swift
//  Sonar
//
//  Created by NHSX on 25/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit


class ErrorView: IBView {
    let colour = UIColor(named: "NHS Error")!
    
    @IBOutlet weak var title: UILabel! 
    @IBOutlet weak var errorMessage: AccessibleErrorLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        title.text = "There is a problem"
        errorMessage.text = "Something is incorrect"
        
        layer.borderWidth = 3
        layer.borderColor = colour.cgColor
    }
}
