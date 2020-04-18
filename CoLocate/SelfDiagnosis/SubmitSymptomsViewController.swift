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
    private var notificationCenter: NotificationCenter!
    private var symptoms: Set<Symptom>!

    func inject(
        persisting: Persisting,
        contactEventRepository: ContactEventRepository,
        session: Session,
        notificationCenter: NotificationCenter,
        hasHighTemperature: Bool,
        hasNewCough: Bool
    ) {
        self.persisting = persisting
        self.contactEventRepository = contactEventRepository
        self.session = session
        self.notificationCenter = notificationCenter

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
    @IBOutlet weak var startDateView: UIView!
    @IBOutlet weak var thankYouLabel: UILabel!
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

        startDateView.isHidden = symptoms.isEmpty

        thankYouLabel.text = "SUBMIT_SYMPTOMS_THANK_YOU".localized

        addKeyboardObservers()
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
            alert(message: "START_DATE_ERROR".localized)
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
            case .success(_):
                self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
                self.contactEventRepository.reset()
            case .failure(let error):
                self.alert(message: error.localizedDescription)
            }
        }
    }

    private func alert(message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard

    private func addKeyboardObservers() {
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(notification: Notification) {
        guard
            let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.size.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        var visibleRegion = self.view.frame
        visibleRegion.size.height -= kbFrame.height

        animate(withKeyboardNotification: notification, animations: {
            self.heightConstraint.constant = visibleRegion.size.height
            self.heightConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            guard let startDateButton = self.startDateViewController.button else { return }
            self.scrollView.scrollRectToVisible(startDateButton.frame, animated: true)
        })
    }

    @objc func keyboardWillHide(notification: Notification) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        animate(withKeyboardNotification: notification, animations: {
            self.heightConstraint.isActive = false
            self.view.layoutIfNeeded()
        })
    }

    private func animate(withKeyboardNotification notification: Notification, animations: @escaping () -> (), completion: @escaping (Bool) -> () = { _ in }) {
        guard
            let kbDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let kbCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            return
        }

        UIView.animate(
            withDuration: kbDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: kbCurve),
            animations: animations,
            completion: completion
        )
    }
}

// MARK: - StartDateViewControllerDelegate

extension SubmitSymptomsViewController: StartDateViewControllerDelegate {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date) {
        startDate = date
    }
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
