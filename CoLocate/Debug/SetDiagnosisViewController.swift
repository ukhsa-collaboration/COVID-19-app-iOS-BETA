//
//  SetDiagnosisViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL
class SetDiagnosisViewController: UITableViewController {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    private var persistence: Persisting!

    func inject(persistence: Persisting) {
        self.persistence = persistence
    }

    @IBOutlet weak var temperatureSwitch: UISwitch!
    @IBOutlet weak var coughSwitch: UISwitch!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var recordedDateTextField: UITextField!
    @IBOutlet weak var updateLabel: UILabel!
    @IBOutlet weak var clearLabel: UILabel!
    @IBOutlet var accessoryToolbar: UIToolbar!
    @IBOutlet var startDatePicker: UIDatePicker!
    @IBOutlet var recordedDatePicker: UIDatePicker!

    var startDate: Date? {
        didSet {
            startDateTextField.text = startDate.map { dateFormatter.string(from: $0) }
        }
    }
    var recordedDate: Date? {
        didSet {
            recordedDateTextField.text = recordedDate.map { dateFormatter.string(from: $0) }
        }
    }

    override func viewDidLoad() {
        updateLabel.textColor = UIColor(named: "NHS Blue")
        clearLabel.textColor = UIColor(named: "NHS Error")

        startDateTextField.placeholder = "N/A"
        startDateTextField.inputView = startDatePicker
        startDateTextField.inputAccessoryView = accessoryToolbar
        recordedDateTextField.placeholder = "N/A"
        recordedDateTextField.inputView = recordedDatePicker
        recordedDateTextField.inputAccessoryView = accessoryToolbar

        render()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath {

        case [0, 0]: temperatureSwitch.isOn = !temperatureSwitch.isOn
        case [0, 1]: coughSwitch.isOn = !coughSwitch.isOn
        case [1, 0]: startDateTextField.becomeFirstResponder()
        case [1, 1]: recordedDateTextField.becomeFirstResponder()

        case [2, 0]:
            var symptoms: Set<Symptom> = []
            if (temperatureSwitch.isOn) { symptoms.insert(.temperature) }
            if (coughSwitch.isOn) { symptoms.insert(.cough) }
            persistence.selfDiagnosis = SelfDiagnosis(
                symptoms: symptoms,
                startDate: startDate ?? Date(),
                recordedDate: recordedDate ?? Date()
            )
            render()

        case [2, 1]:
            persistence.selfDiagnosis = nil
            performSegue(withIdentifier: "unwindFromSetDiagnosis", sender: self)

        default:
            fatalError()
        }
    }

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        switch sender {
        case startDatePicker:
            startDate = sender.date
        case recordedDatePicker:
            recordedDate = sender.date
        default:
            fatalError()
        }
    }

    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        startDateTextField.resignFirstResponder()
        recordedDateTextField.resignFirstResponder()
    }

    private func render() {
        let diagnosis = persistence.selfDiagnosis

        temperatureSwitch.isOn = diagnosis.map { $0.symptoms.contains(.temperature) } ?? false
        coughSwitch.isOn = diagnosis.map { $0.symptoms.contains(.cough) } ?? false

        startDate = diagnosis?.startDate
        recordedDate = diagnosis?.recordedDate
    }

}
#endif
