//
//  SymptomsViewController.swift
//  Sonar
//
//  Created by NHSX on 4/27/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

class SymptomsSummaryViewController: UIViewController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    private var symptoms: Set<Symptom>!
    private var statusStateMachine: StatusStateMachining!
    private var completion: ((Set<Symptom>) -> Void)!

    func inject(
        hasHighTemperature: Bool,
        hasNewCough: Bool,
        statusStateMachine: StatusStateMachining,
        completion: @escaping (Set<Symptom>) -> Void
    ) {
        self.statusStateMachine = statusStateMachine
        self.completion = completion

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
                symptoms: symptoms,
                startDate: startDate,
                statusStateMachine: statusStateMachine,
                completion: completion
            )
        default:
            break
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        completion([])
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
        UIApplication.shared.open(ContentURLs.shared.nhs111Coronavirus)
    }

    @IBAction func buttonTapped(_ sender: PrimaryButton) {
        if symptoms.isEmpty {
            completion(symptoms)
            return
        }

        guard startDate != nil else {
            // ideally we'd only hide / show one of these, not both
            // but the error label triggers a UIAccessibility notification for voice over
            // and the error view is used to provide a margin between elements
            // because the error label is presented inside of a stack view
            // TODO : remove the erroview.isHidden here if you refactor away from nested stack views
            scroll(after: {
                self.startDateViewController.errorView.isHidden = false
                self.startDateViewController.errorLabel.isHidden = false
            }, to: startDateViewController.errorLabel)
            
            return
        }

        performSegue(withIdentifier: "showSubmitSymptoms", sender: self)
    }
}

// MARK: - StartDateViewControllerDelegate

extension SymptomsSummaryViewController: StartDateViewControllerDelegate {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date) {
        startDate = date
    }
    
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
