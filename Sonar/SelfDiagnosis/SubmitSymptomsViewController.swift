//
//  SubmitSymptomsViewController.swift
//  Sonar
//
//  Created by NHSX on 4/7/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class SubmitSymptomsViewController: UIViewController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    // MARK: - Dependencies

    private var symptoms: Symptoms!
    private var startDate: Date!
    private var statusStateMachine: StatusStateMachining!
    private var completion: ((Symptoms) -> Void)!

    func inject(
        symptoms: Symptoms,
        startDate: Date,
        statusStateMachine: StatusStateMachining,
        completion: @escaping (Symptoms) -> Void
    ) {
        self.symptoms = symptoms
        self.startDate = startDate
        self.statusStateMachine = statusStateMachine
        self.completion = completion
    }

    // MARK: - UIKit

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var submitButton: PrimaryButton!
    @IBOutlet weak var confirmSwitch: UISwitch!
    @IBOutlet var errorLabel: AccessibleErrorLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        thankYouLabel.text = "SUBMIT_SYMPTOMS_THANK_YOU".localized
        confirmLabel.text = "SUBMIT_SYMPTOMS_CONFIRM".localized
        confirmSwitch.accessibilityLabel = "Please toggle the switch to confirm the information you entered is accurate"
        errorLabel.isHidden = true
    }

    @IBAction func cancelTapped(_ sender: Any) {
        completion([])
    }

    private var isSubmitting = false
    @IBAction func submitTapped(_ sender: PrimaryButton) {
        defer {
            isSubmitting = false
        }

        guard !isSubmitting, validateConfirmation() else { return }
        isSubmitting = true

        do {
            switch statusStateMachine.state {
            case .ok, .exposed:
                try statusStateMachine.selfDiagnose(symptoms: symptoms, startDate: startDate)
            case .symptomatic, .checkin, .unexposed:
                assertionFailure("We should only be able to submit symptoms from ok/exposed")
                return
            }

            completion(symptoms)
        } catch {
            alert(with: Error())
        }
    }

    struct Error: Swift.Error {
        var localizedDescription: String { "An unexpected error occurred" }
    }

    private func alert(with error: Error) {
        let alert = UIAlertController(
            title: "Error uploading contact events",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Okay", style: .default))
        present(alert, animated: true)
    }
    
    private func validateConfirmation() -> Bool {
        if confirmSwitch.isOn {
            return true
        } else {
            scroll(after: {
                self.presentErrorToUser()
            }, toErrorLabel: errorLabel, orControl: confirmSwitch)
            
            return false
        }
    }

    private func presentErrorToUser() {
        errorLabel.isHidden = false

        confirmSwitch.layer.borderWidth = 3
        confirmSwitch.layer.borderColor = UIColor(named: "NHS Error")!.cgColor
        confirmSwitch.layer.cornerRadius = 16
    }
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
