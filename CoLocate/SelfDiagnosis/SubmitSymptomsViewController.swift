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

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var startDateView: UIStackView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDateButton: StartDateButton!
    @IBOutlet weak var submitButton: PrimaryButton!
    @IBOutlet var datePickerAccessory: UIToolbar!
    @IBOutlet var datePicker: UIPickerView!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private var persisting: Persisting!
    private var contactEventRepository: ContactEventRepository!
    private var session: Session!
    private var notificationCenter: NotificationCenter!

    private var symptoms: Set<Symptom>!
    var startDateOptions: [Date] = {
        let today = Date()
        return (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }.reversed()
    }()
    private var startDate: Date? {
        didSet {
            guard let date = startDate else {
                return
            }

            startDateButton.text = dateFormatter.string(from: date)
        }
    }
    private var isSubmitting = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        summaryLabel.text = "QUESTION_SUMMARY".localized
        if symptoms.isEmpty {
            startDateView.isHidden = true
        } else {
            startDateView.isHidden = false

            let question: String
            if symptoms.count > 1 {
                question = "SYMPTOMS_START_QUESTION"
            } else if symptoms == [.temperature] {
                question = "TEMPERATURE_START_QUESTION"
            } else if symptoms == [.cough] {
                question = "COUGH_START_QUESTION"
            } else {
                logger.critical("Unknown symptoms: \(String(describing: symptoms))")
                question = "SYMPTOMS_START_QUESTION"
            }
            startDateLabel.text = question.localized
        }

        startDateButton.text = "SELECT_START_DATE".localized
        startDateButton.inputView = datePicker
        startDateButton.inputAccessoryView = datePickerAccessory

        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @IBAction func startDateButtonTapped(_ sender: StartDateButton) {
        startDateButton.becomeFirstResponder()
    }

    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        startDateButton.resignFirstResponder()
    }

    @IBAction func startDateChanged(_ sender: UIDatePicker) {
        startDate = sender.date
    }

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

    @objc func keyboardDidShow(notification: Notification) {
        guard let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.size.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        var visibleRegion = self.view.frame
        visibleRegion.size.height -= kbFrame.height

        scrollView.scrollRectToVisible(submitButton.frame, animated: true)
    }

    @objc func keyboardWillHide(notification: Notification) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
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

}

extension SubmitSymptomsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return startDateOptions.count
    }
}

extension SubmitSymptomsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dateFormatter.string(from: startDateOptions[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        startDate = startDateOptions[row]
    }
}

class StartDateButton: ButtonWithDynamicType {
    override var canBecomeFirstResponder: Bool {
        true
    }

    private var _inputView: UIView?
    override var inputView: UIView? {
        get { _inputView }
        set { _inputView = newValue }
    }

    private var _inputAccessoryView: UIView?
    override var inputAccessoryView: UIView? {
        get { _inputAccessoryView }
        set { _inputAccessoryView = newValue }
    }

    var text: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 16
    }
}

fileprivate let logger = Logger(label: "SelfDiagnosis")
