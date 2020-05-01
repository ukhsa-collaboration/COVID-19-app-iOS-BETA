//
//  SymptomsViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

class SymptomsSummaryViewController: UIViewController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    private var persisting: Persisting!
    private var contactEventsUploader: ContactEventsUploader!
    private var symptoms: Set<Symptom>!
    private var statusViewController: StatusViewController!
    private var localNotificationScheduler: Scheduler!

    func inject(
        persisting: Persisting,
        contactEventsUploader: ContactEventsUploader,
        hasHighTemperature: Bool,
        hasNewCough: Bool,
        statusViewController: StatusViewController,
        localNotificationScheduler: Scheduler
    ) {
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader
        self.statusViewController = statusViewController
        self.localNotificationScheduler = localNotificationScheduler
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
    @IBOutlet weak var button: PrimaryButton!

    var startDateViewController: StartDateViewController!
    private var startDate: Date?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as StartDateViewController:
            startDateViewController = vc
            vc.inject(symptoms: symptoms, delegate: self)
        case let vc as SubmitSymptomsViewController:
            guard let startDate = startDate else { return }

            vc.inject(
                persisting: persisting,
                contactEventsUploader: contactEventsUploader,
                symptoms: symptoms,
                startDate: startDate,
                statusViewController: statusViewController,
                localNotificationScheduler: localNotificationScheduler
            )
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        haveSymptomsView.isHidden = symptoms.isEmpty
        checkAnswersLabel.text = "SYMPTOMS_SUMMARY_CHECK_ANSWERS".localized
        temperatureCheckLabel.text = "SYMPTOMS_SUMMARY_\(symptoms.contains(.temperature) ? "HAVE" : "NO")_TEMPERATURE".localized
        coughCheckLabel.text = "SYMPTOMS_SUMMARY_\(symptoms.contains(.cough) ? "HAVE" : "NO")_COUGH".localized

        noSymptomsView.isHidden = !symptoms.isEmpty
        noSymptomsLabel.text = "SYMPTOMS_SUMMARY_NO_SYMPTOMS".localized
        noSymptomsInfoLabel.text = "SYMPTOMS_SUMMARY_NO_SYMPTOMS_INFO".localized
        noSymptomsInfoButton.setTitle("SYMPTOMS_SUMMARY_NO_SYMPTOMS_NHS_111".localized, for: .normal)
        noSymptomsInfoButton.contentHorizontalAlignment = .leading

        let buttonTitle = symptoms.isEmpty ? "SYMPTOMS_SUMMARY_DONE" : "SYMPTOMS_SUMMARY_CONTINUE"
        button.setTitle(buttonTitle.localized, for: .normal)
    }

    @IBAction func noSymptomsInfoTapped(_ sender: ButtonWithDynamicType) {
        UIApplication.shared.open(URL(string: "https://111.nhs.uk/covid-19/")!)
    }

    @IBAction func buttonTapped(_ sender: PrimaryButton) {
        if symptoms.isEmpty {
            performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
            return
        }

        guard startDate != nil else {
            startDateViewController.errorView.isHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: startDateViewController.errorView)
            
            DispatchQueue.main.async {
                let errorLabel: UILabel = self.startDateViewController.errorLabel
                let targetRect = errorLabel.convert(errorLabel.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(targetRect, animated: true)
            }
            return
        }

        performSegue(withIdentifier: "showSubmitSymptoms", sender: self)
    }
}

// MARK: - StartDateViewControllerDelegate

extension SymptomsSummaryViewController: StartDateViewControllerDelegate {
    func startDateViewControllerDidShowDatePicker(_ vc: StartDateViewController) {
        // Scroll the date picker into view
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.05) {
                self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.frame.height)
            }
        }
    }
    
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date) {
        startDate = date
    }
    
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
