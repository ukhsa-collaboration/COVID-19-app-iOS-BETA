//
//  TemperatureViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TemperatureViewController: UIViewController {
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionLabel.text = "TEMPERATURE_QUESTION".localized
        detailLabel.text = "TEMPERATURE_DETAIL".localized
        errorLabel.text = "TEMPERATURE_ERROR".localized
        yesButton.text = "TEMPERATURE_YES".localized
        noButton.text = "TEMPERATURE_NO".localized
        errorLabel.textColor = UIColor(named: "NHS Error")
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
