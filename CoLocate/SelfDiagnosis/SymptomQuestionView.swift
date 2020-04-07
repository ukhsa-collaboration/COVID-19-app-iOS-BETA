//
//  SymptomQuestionView.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomQuestionView: UITableViewHeaderFooterView {
    static let reuseIdentifier: String = String(describing: SymptomQuestionView.self)

    static var nib: UINib {
        return UINib(nibName: String(describing: SymptomQuestionView.self), bundle: nil)
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

}

