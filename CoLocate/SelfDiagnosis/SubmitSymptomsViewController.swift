//
//  SubmitSymptomsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class SubmitSymptomsViewController: UIViewController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    // MARK: - Dependencies

    private var persisting: Persisting!
    private var contactEventsUploader: ContactEventsUploader!
    private var symptoms: Set<Symptom>!

    func inject(
        persisting: Persisting,
        contactEventsUploader: ContactEventsUploader,
        hasHighTemperature: Bool,
        hasNewCough: Bool
    ) {
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader

        symptoms = Set()
        if hasHighTemperature {
            symptoms.insert(.temperature)
        }
        if hasNewCough {
            symptoms.insert(.cough)
        }
    }

    // MARK: - UIKit

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var haveSymptomsView: UIStackView!
    @IBOutlet weak var checkAnswersLabel: UILabel!
    @IBOutlet weak var temperatureCheckLabel: UILabel!
    @IBOutlet weak var coughCheckLabel: UILabel!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var noSymptomsView: UIStackView!
    @IBOutlet weak var noSymptomsLabel: UILabel!
    @IBOutlet weak var noSymptomsInfoLabel: UILabel!
    @IBOutlet weak var noSymptomsInfoButton: UIButton!

    @IBOutlet weak var submitErrorView: UIView!
    @IBOutlet weak var submitErrorLabel: UILabel!
    @IBOutlet weak var submitButton: PrimaryButton!

    var startDateViewController: StartDateViewController!
    private var startDate: Date?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as StartDateViewController:
            startDateViewController = vc
            vc.inject(symptoms: symptoms, delegate: self)
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        haveSymptomsView.isHidden = symptoms.isEmpty
        checkAnswersLabel.text = "SUBMIT_SYMPTOMS_CHECK_ANSWERS".localized
        temperatureCheckLabel.text = "SUBMIT_SYMPTOMS_\(symptoms.contains(.temperature) ? "HAVE" : "NO")_TEMPERATURE".localized
        coughCheckLabel.text = "SUBMIT_SYMPTOMS_\(symptoms.contains(.cough) ? "HAVE" : "NO")_COUGH".localized

        noSymptomsView.isHidden = !symptoms.isEmpty
        noSymptomsLabel.text = "SUBMIT_SYMPTOMS_NO_SYMPTOMS".localized
        noSymptomsInfoLabel.text = "SUBMIT_SYMPTOMS_NO_SYMPTOMS_INFO".localized
        noSymptomsInfoButton.setTitle("SUBMIT_SYMPTOMS_NO_SYMPTOMS_NHS_111".localized, for: .normal)
        noSymptomsInfoButton.contentHorizontalAlignment = .leading

        submitErrorLabel.textColor = UIColor(named: "NHS Error")
        submitErrorLabel.text = "SUBMIT_SYMPTOMS_ERROR".localized
        thankYouLabel.text = "SUBMIT_SYMPTOMS_THANK_YOU".localized
    }

    private var isSubmitting = false
    @IBAction func submitTapped(_ sender: PrimaryButton) {
        guard !symptoms.isEmpty else {
            self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
            return
        }

        guard let startDate = startDate else {
            startDateViewController.errorView.isHidden = false
            scrollView.scrollRectToVisible(startDateViewController.errorLabel.frame, animated: true)
            return
        }

        guard !isSubmitting else { return }
        isSubmitting = true

        persisting.selfDiagnosis = SelfDiagnosis(symptoms: symptoms, startDate: startDate, expiryDate: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60))

        do {
            try contactEventsUploader.upload()
            self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
        } catch {
            alert(with: Error())
        }
    }

    struct Error: Swift.Error {
        var localizedDescription: String { "oh no" }
    }

    @IBAction func noSymptomsInfoTapped(_ sender: ButtonWithDynamicType) {
        UIApplication.shared.open(URL(string: "https://111.nhs.uk/covid-19/")!)
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
}

// MARK: - StartDateViewControllerDelegate

extension SubmitSymptomsViewController: StartDateViewControllerDelegate {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date) {
        startDate = date
    }
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
