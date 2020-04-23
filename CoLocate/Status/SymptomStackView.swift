//
//  SymptomStackView.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomStackView: UIStackView {
    var temperatureLabel: UILabel {
        let label = UILabel()
        label.text = "High Temperature"
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        return label
    }
    
    var coughLabel: UILabel {
        let label = UILabel()
        label.text = "Continous Cough"
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
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
                    return
                }
                
                if symptoms.contains(.cough) {
                    addArrangedSubview(coughLabel)
                    return
                }
            }
            addArrangedSubview(UILabel())
        }
    }
}
