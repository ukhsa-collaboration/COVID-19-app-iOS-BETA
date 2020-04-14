//
//  CoughViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CoughViewController: UIViewController {
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!

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
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionLabel.text = "COUGH_QUESTION".localized
        detailLabel.text = "COUGH_DETAIL".localized
        errorLabel.text = "COUGH_ERROR".localized
        yesButton.setTitle("COUGH_YES".localized, for: .normal)
        noButton.setTitle("COUGH_NO".localized, for: .normal)
        errorLabel.textColor = UIColor(named: "NHS Error")
    }

    @IBAction func yesTapped(_ sender: AnswerButton) {
        hasNewCough = true
    }

    @IBAction func noTapped(_ sender: AnswerButton) {
        hasNewCough = false
    }

    @IBAction func continueTapped(_ sender: PrimaryButton) {
        guard hasNewCough != nil else {
            errorLabel.isHidden = false
            return
        }

        performSegue(withIdentifier: "submitSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SubmitSymptomsViewController {
            vc.hasHighTemperature = hasHighTemperature
            vc.hasNewCough = hasNewCough
        }
    }
}
