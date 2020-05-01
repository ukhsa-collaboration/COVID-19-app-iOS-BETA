//
//  SubmitSymptomsViewController.swift
//  Sonar
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
    private var startDate: Date!
    private var statusViewController: StatusViewController?
    private var localNotificationScheduler: Scheduler!

    func inject(
        persisting: Persisting,
        contactEventsUploader: ContactEventsUploader,
        symptoms: Set<Symptom>,
        startDate: Date,
        statusViewController: StatusViewController?,
        localNotificationScheduler: Scheduler
    ) {
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader
        self.statusViewController = statusViewController
        self.symptoms = symptoms
        self.startDate = startDate
        self.localNotificationScheduler = localNotificationScheduler
    }

    // MARK: - UIKit

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var submitButton: PrimaryButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        thankYouLabel.text = "SUBMIT_SYMPTOMS_THANK_YOU".localized
        confirmLabel.text = "SUBMIT_SYMPTOMS_CONFIRM".localized
    }

    private var isSubmitting = false
    @IBAction func submitTapped(_ sender: PrimaryButton) {
        defer {
            isSubmitting = false
        }

        guard !isSubmitting else { return }
        isSubmitting = true

        do {
            navigationController?.dismiss(animated: true, completion: nil)
            
            let hasCough = symptoms.contains(.cough)
            var selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: symptoms, startDate: startDate)
            selfDiagnosis.expiresIn(days: 7)
                    
            if symptoms.contains(.temperature) || (hasCough && !selfDiagnosis.hasExpired()) {
                if selfDiagnosis.hasExpired() {
                    selfDiagnosis = SelfDiagnosis(type: .subsequent, symptoms: symptoms, startDate: Date())
                    selfDiagnosis.expiresIn(days: 1)
                }

                persisting.selfDiagnosis = selfDiagnosis

                // This needs to go after persisting the self-diagnosis
                try contactEventsUploader.upload()

                localNotificationScheduler.scheduleDiagnosisNotification(expiryDate: selfDiagnosis.expiryDate)
            } else {
                if hasCough {
                    statusViewController?.updatePrompt()
                }
                persisting.selfDiagnosis = nil
            }
            
        } catch {
            alert(with: Error())
        }
    }

    struct Error: Swift.Error {
        var localizedDescription: String { "oh no" }
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
