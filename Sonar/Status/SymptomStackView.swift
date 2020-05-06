//
//  SymptomStackView.swift
//  Sonar
//
//  Created by NHSX on 22/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomStackView: UIStackView {
    var temperatureLabel: UILabel {
        let label = UILabel()
        label.text = "High temperature"
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = UIColor(named: "NHS Secondary Text")
        return label
    }
    
    var coughLabel: UILabel {
        let label = UILabel()
        label.text = "Continuous cough"
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = UIColor(named: "NHS Secondary Text")
        return label
    }
    
    var symptoms: Set<Symptom>? {
        didSet {
            arrangedSubviews.forEach({view in
                view.removeFromSuperview()
            })
            
            if let symptoms = symptoms {
                if symptoms.contains(.temperature) {
                    addArrangedSubview(temperatureLabel)
                }
                
                if symptoms.contains(.cough) {
                    addArrangedSubview(coughLabel)
                }
            }
            addArrangedSubview(UILabel())
        }
    }
}
