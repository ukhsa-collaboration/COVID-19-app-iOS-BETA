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

    private var symptoms: Symptoms!
    private var statusStateMachine: StatusStateMachining!
    private var completion: ((Symptoms) -> Void)!
    private var pageNumber: Int!

    func inject(
        pageNumber: Int,
        symptoms: Symptoms,
        statusStateMachine: StatusStateMachining,
        completion: @escaping (Symptoms) -> Void
    ) {
        self.statusStateMachine = statusStateMachine
        self.completion = completion
        self.symptoms = symptoms
        self.pageNumber = pageNumber
    }

    // MARK: - UIKit

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var haveSymptomsView: UIStackView!
    @IBOutlet weak var checkAnswersLabel: UILabel!
    @IBOutlet weak var noSymptomsView: UIStackView!
    @IBOutlet weak var noSymptomsLabel: UILabel!
    @IBOutlet weak var noSymptomsInfoLabel: UILabel!
    @IBOutlet weak var noSymptomsInfoButton: UIButton!
    @IBOutlet weak var button: PrimaryButton!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var checkAnswersStackView: UIStackView!
    
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

        haveSymptomsView.isHidden = !symptoms.hasCoronavirusSymptoms
        checkAnswersLabel.text = "SYMPTOMS_SUMMARY_CHECK_ANSWERS".localized

        noSymptomsView.isHidden = symptoms.hasCoronavirusSymptoms
        noSymptomsLabel.text = "SYMPTOMS_SUMMARY_NO_SYMPTOMS".localized
        noSymptomsInfoLabel.text = "SYMPTOMS_SUMMARY_NO_SYMPTOMS_INFO".localized
        noSymptomsInfoButton.setTitle("SYMPTOMS_SUMMARY_NO_SYMPTOMS_NHS_111".localized, for: .normal)
        noSymptomsInfoButton.contentHorizontalAlignment = .leading

        let buttonTitle = symptoms.hasCoronavirusSymptoms ? "SYMPTOMS_SUMMARY_CONTINUE" : "SYMPTOMS_SUMMARY_DONE"
        button.setTitle(buttonTitle.localized, for: .normal)
    
        // This assumes this is the last page of the questionnaire
        pageNumberLabel.text = "\(pageNumber!)/\(pageNumber!)"
        pageNumberLabel.accessibilityLabel = "Step \(pageNumber!) of \(pageNumber!)"

        let symptomTexts = [
            "SYMPTOMS_SUMMARY_\(symptoms.contains(.temperature) ? "HAVE" : "NO")_TEMPERATURE".localized,
            "SYMPTOMS_SUMMARY_\(symptoms.contains(.cough) ? "HAVE" : "NO")_COUGH".localized,
            "SYMPTOMS_SUMMARY_\(symptoms.contains(.smellLoss) ? "HAVE" : "NO")_SMELL_LOSS".localized,
            "SYMPTOMS_SUMMARY_\(symptoms.contains(.fever) ? "HAVE" : "NO")_FEVER".localized,
            "SYMPTOMS_SUMMARY_\(symptoms.contains(.nausea) ? "HAVE" : "NO")_NAUSEA".localized,
        ]
        
        symptomTexts.forEach { symptomText in
            let divider = UIView()
            divider.backgroundColor = UIColor(named: "NHS Grey 3")
            checkAnswersStackView.addArrangedSubview(divider)
            
            let label = UILabel()
            label.text = symptomText
            label.sizeToFit()
            label.translatesAutoresizingMaskIntoConstraints = false

            let view = UIView()
            view.addSubview(label)
            
            checkAnswersStackView.addArrangedSubview(view)
            
            NSLayoutConstraint.activate([
                divider.heightAnchor.constraint(equalToConstant: 1),
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
                view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
                view.rightAnchor.constraint(equalTo: label.rightAnchor, constant: 10)
            ])
        }
    }

    @IBAction func noSymptomsInfoTapped(_ sender: ButtonWithDynamicType) {
        UIApplication.shared.open(ContentURLs.shared.nhs111Coronavirus)
    }

    @IBAction func buttonTapped(_ sender: PrimaryButton) {
        if !symptoms.hasCoronavirusSymptoms {
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
