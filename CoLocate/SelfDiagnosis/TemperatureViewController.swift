//
//  TemperatureViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TemperatureViewController: UIViewController {
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!

    var hasHighTemperature: Bool? {
        didSet {
            yesButton.isSelected = false
            noButton.isSelected = false

            switch hasHighTemperature {
            case .some(true):
                yesButton.isSelected = true
            case .some(false):
                noButton.isSelected = true
            case .none:
                break
            }
        }
    }

    @IBAction func yesTapped(_ sender: AnswerButton) {
        hasHighTemperature = true
    }

    @IBAction func noTapped(_ sender: AnswerButton) {
        hasHighTemperature = false
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        guard hasHighTemperature != nil else {
            errorLabel.isHidden = false
            return
        }

        performSegue(withIdentifier: "coughSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CoughViewController {
            vc.hasHighTemperature = hasHighTemperature
        }
    }
}
