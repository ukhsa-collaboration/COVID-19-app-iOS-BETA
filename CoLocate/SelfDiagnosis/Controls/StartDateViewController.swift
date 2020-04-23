//
//  StartDateViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

protocol StartDateViewControllerDelegate: class {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date)
}

class StartDateViewController: UIViewController {

    private var symptoms: Set<Symptom>!
    weak var delegate: StartDateViewControllerDelegate?

    func inject(symptoms: Set<Symptom>, delegate: StartDateViewControllerDelegate) {
        self.symptoms = symptoms
        self.delegate = delegate
    }

    private var startDate: Date? {
        didSet {
            guard let date = startDate else {
                return
            }

            errorView.isHidden = true

            button.text = dateFormatter.string(from: date)
            delegate?.startDateViewController(self, didSelectDate: date)
        }
    }

    private let logger = Logger(label: String(describing: self))

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var button: StartDateButton!

    @IBOutlet var datePickerAccessory: UIToolbar!
    @IBOutlet var datePicker: UIPickerView!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var dateOptions: [Date] = {
        let today = Date()
        return (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }.reversed()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

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
        label.text = question.localized

        errorLabel.textColor = UIColor(named: "NHS Error")
        errorLabel.text = "SELECT_START_DATE_ERROR".localized

        button.text = "SELECT_START_DATE".localized
    }

    @IBAction func buttonTapped(_ sender: StartDateButton) {
        self.datePicker.isHidden = !self.datePicker.isHidden
    }

}

extension StartDateViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dateOptions.count
    }
}

extension StartDateViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dateFormatter.string(from: dateOptions[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        startDate = dateOptions[row]
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
