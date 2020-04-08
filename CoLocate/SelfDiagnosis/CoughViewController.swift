//
//  CoughViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CoughViewController: UIViewController {
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!

    @IBOutlet weak var continueButton: PrimaryButton!

    var hasHighTemperature: Bool!
    var hasNewCough: Bool? {
        didSet {
            yesButton.isSelected = false
            noButton.isSelected = false

            switch hasNewCough {
            case .some(true):
                yesButton.isSelected = true
            case .some(false):
                noButton.isSelected = true
            case .none:
                break
            }

            continueButton?.isEnabled = hasNewCough != nil
        }
    }

    @IBAction func yesTapped(_ sender: AnswerButton) {
        hasNewCough = true
    }

    @IBAction func noTapped(_ sender: AnswerButton) {
        hasNewCough = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SubmitSymptomsViewController {
            vc.hasHighTemperature = hasHighTemperature
            vc.hasNewCough = hasNewCough
        }
    }
}
