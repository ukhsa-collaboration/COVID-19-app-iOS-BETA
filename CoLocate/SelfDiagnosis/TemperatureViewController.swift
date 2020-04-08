//
//  TemperatureViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TemperatureViewController: UIViewController {
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!

    @IBOutlet weak var continueButton: PrimaryButton!

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

            continueButton?.isEnabled = hasHighTemperature != nil
        }
    }

    @IBAction func yesTapped(_ sender: AnswerButton) {
        hasHighTemperature = true
    }

    @IBAction func noTapped(_ sender: AnswerButton) {
        hasHighTemperature = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CoughViewController {
            vc.hasHighTemperature = hasHighTemperature
        }
    }

    @objc private func continueTapped(_ sender: PrimaryButton) {
        sender.isEnabled = false

        performSegue(withIdentifier: "segueToCough", sender: self)
    }
}
