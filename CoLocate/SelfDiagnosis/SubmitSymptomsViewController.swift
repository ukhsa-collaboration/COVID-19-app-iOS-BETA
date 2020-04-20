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
    private var contactEventRepository: ContactEventRepository!
    private var session: Session!
    private var symptoms: Set<Symptom>!

    func inject(
        persisting: Persisting,
        contactEventRepository: ContactEventRepository,
        session: Session,
        hasHighTemperature: Bool,
        hasNewCough: Bool
    ) {
        self.persisting = persisting
        self.contactEventRepository = contactEventRepository
        self.session = session

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

        submitErrorLabel.textColor = UIColor(named: "NHS Error")
        submitErrorLabel.text = "SUBMIT_SYMPTOMS_ERROR".localized
        thankYouLabel.text = "SUBMIT_SYMPTOMS_THANK_YOU".localized
    }

    private var isSubmitting = false
    @IBAction func submitTapped(_ sender: PrimaryButton) {
        guard let registration = persisting.registration else {
            fatalError("What do we do when we aren't registered?")
        }

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
        
        // NOTE: This is not spec'ed out, and is only here
        // so we can make sure this flow works through the
        // app during debugging. This will need to be replaced
        // with real business logic in the future.
        persisting.selfDiagnosis = SelfDiagnosis(symptoms: symptoms, startDate: startDate)
        
        let requestFactory = ConcreteSecureRequestFactory(registration: registration)

        let contactEvents = contactEventRepository.contactEvents.compactMap { contactEvent -> ContactEvent in
            let uuid = contactEvent.sonarId.flatMap { UUID(data: $0) }
            guard !Persistence.shared.enableNewKeyRotation, uuid != nil else {
                return contactEvent
            }

            var ce = contactEvent
            ce.sonarId = uuid?.uuidString.data(using: .utf8)
            return ce
        }

        let request = requestFactory.patchContactsRequest(contactEvents: contactEvents)
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self else { return }
            
            self.isSubmitting = false

            switch result {
            case .success:
                self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
                self.contactEventRepository.reset()
            case .failure:
                self.submitErrorView.isHidden = false
            }
        }
    }

}

// MARK: - StartDateViewControllerDelegate

extension SubmitSymptomsViewController: StartDateViewControllerDelegate {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date) {
        startDate = date
    }
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
