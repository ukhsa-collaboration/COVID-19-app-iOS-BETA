//
//  ButtonFooterView.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ButtonFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier: String = String(describing: ButtonFooterView.self)

    static var nib: UINib {
        return UINib(nibName: String(describing: ButtonFooterView.self), bundle: nil)
    }

    @IBOutlet weak var continueButton: PrimaryButton!

}

