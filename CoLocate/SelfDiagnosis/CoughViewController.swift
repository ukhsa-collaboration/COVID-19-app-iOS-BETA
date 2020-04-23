//
//  CoughViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CoughViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!
    @IBOutlet weak var continueButton: PrimaryButton!

    private var persistence: Persisting!
    private var contactEventsUploader: ContactEventsUploader!

    func inject(
        persistence: Persisting,
        contactEventsUploader: ContactEventsUploader,
        hasHighTemperature: Bool
    ) {
        self.persistence = persistence
        self.contactEventsUploader = contactEventsUploader

        self.hasHighTemperature = hasHighTemperature
    }

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
        yesButton.text = "COUGH_YES".localized
        noButton.text = "COUGH_NO".localized
        errorLabel.textColor = UIColor(named: "NHS Error")
    }

    @IBAction func yesTapped(_ sender: AnswerButton) {
        hasNewCough = true

        scrollView.scrollRectToVisible(continueButton.frame, animated: true)
    }

    @IBAction func noTapped(_ sender: AnswerButton) {
        hasNewCough = false

        scrollView.scrollRectToVisible(continueButton.frame, animated: true)
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
            vc.inject(
                persisting: persistence,
                contactEventsUploader: contactEventsUploader,
                hasHighTemperature: hasHighTemperature,
                hasNewCough: hasNewCough!)
        }
    }
}
