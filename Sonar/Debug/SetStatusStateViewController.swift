//
//  SetStatusStateViewController.swift
//  Sonar
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SetStatusStateViewController: UITableViewController {

    @IBOutlet var statusStateCell: UITableViewCell!
    @IBOutlet var statePickerCell: UITableViewCell!
    @IBOutlet var temperatureCell: UITableViewCell!
    @IBOutlet var coughCell: UITableViewCell!
    @IBOutlet var dateCell: UITableViewCell!
    @IBOutlet var datePickerCell: UITableViewCell!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusPicker: UIPickerView!
    @IBOutlet weak var temperatureSwitch: UISwitch!
    @IBOutlet weak var coughSwitch: UISwitch!
    @IBOutlet weak var dateTitleLabel: UILabel!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!

    var persistence: Persisting!
    var statusStateMachine: StatusStateMachining!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private var temperature: Bool? {
        didSet {
            guard let temperature = temperature else {
                showCell[temperatureCell] = false
                return
            }

            showCell[temperatureCell] = true
            temperatureSwitch.isOn = temperature

            if cough == .some(false), !temperature {
                self.temperature = true
                temperatureSwitch.isOn = true
            }
        }
    }

    private var cough: Bool? {
        didSet {
            guard let cough = cough else {
                showCell[coughCell] = false
                return
            }

            showCell[coughCell] = true
            coughSwitch.isOn = cough

            if temperature == .some(false), !cough {
                self.cough = true
                coughSwitch.isOn = true
            }
        }
    }

    private var symptoms: Symptoms {
        var symptoms: Symptoms = []
        if let temperature = temperature, temperature { symptoms.insert(.temperature) }
        if let cough = cough, cough { symptoms.insert(.cough) }
        return symptoms
    }

    private var date: Date? {
        didSet {
            guard let date = date else {
                showCell[dateCell] = false
                return
            }

            showCell[dateCell] = true
            dateDetailLabel.text = dateFormatter.string(from: date)
        }
    }

    private var cells: [UITableViewCell] {
        [statusStateCell, statePickerCell, temperatureCell, coughCell, dateCell, datePickerCell].filter { showCell[$0] ?? false }
    }
    private var showCell: [UITableViewCell: Bool] = [:] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showCell[statusStateCell] = true
        show(statusState: statusStateMachine.state)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch tableView.cellForRow(at: indexPath) {
        case dateCell:
            showCell[datePickerCell] = showCell[datePickerCell].map { !$0 } ?? true
        case statusStateCell:
            showCell[statePickerCell] = showCell[statePickerCell].map { !$0 } ?? true
        default:
            break
        }
    }

    private func show(statusState: StatusState) {
        switch statusState {
        case .ok:
            statusLabel.text = "ok"
            statusPicker.selectRow(0, inComponent: 0, animated: false)
            temperature = nil
            cough = nil
            date = nil
        case .symptomatic(let symptomatic):
            statusLabel.text = "symptomatic"
            statusPicker.selectRow(1, inComponent: 0, animated: false)
            temperature = symptomatic.symptoms.contains(.temperature)
            cough = symptomatic.symptoms.contains(.cough)
            date = symptomatic.startDate
        case .checkin(let checkin):
            statusLabel.text = "checkin"
            statusPicker.selectRow(2, inComponent: 0, animated: false)
            temperature = checkin.symptoms.map { $0.contains(.temperature) } ?? false
            cough = checkin.symptoms.map { $0.contains(.cough) } ?? false
            date = checkin.checkinDate
        case .exposed(let exposed):
            statusLabel.text = "exposed"
            statusPicker.selectRow(3, inComponent: 0, animated: false)
            temperature = nil
            cough = nil
            date = exposed.startDate
        case .unexposed:
            statusLabel.text = "unexposed"
            statusPicker.selectRow(4, inComponent: 0, animated: false)
            temperature = nil
            cough = nil
            date = nil
        case .positiveTestResult(let positiveTestResult):
            statusLabel.text = "positive test result"
            statusPicker.selectRow(5, inComponent: 0, animated: false)
            temperature = positiveTestResult.symptoms.map { $0.contains(.temperature) } ?? false
            cough = positiveTestResult.symptoms.map { $0.contains(.cough) } ?? false
            date = positiveTestResult.startDate
        case .unclearTestResult(let unclearTestResult):
            statusLabel.text = "unclear test result"
            statusPicker.selectRow(6, inComponent: 0, animated: false)
            temperature = unclearTestResult.symptoms.contains(.temperature)
            cough = unclearTestResult.symptoms.contains(.cough)
            date = unclearTestResult.startDate
        case .negativeTestResult(let negativeTestResult, _):
            statusLabel.text = "negative test result"
            statusPicker.selectRow(7, inComponent: 0, animated: false)
            temperature = negativeTestResult.symptoms.contains(.temperature)
            cough = negativeTestResult.symptoms.contains(.cough)
            date = negativeTestResult.startDate
        }
    }

    @IBAction func temperatureChanged(_ sender: UISwitch) {
        temperature = sender.isOn
    }

    @IBAction func coughChanged(_ sender: UISwitch) {
        cough = sender.isOn
    }

    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        date = sender.date
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        let statusState: StatusState
        switch statusPicker.selectedRow(inComponent: 0) {
        case 0:
            statusState = .ok(StatusState.Ok())
        case 1:
            guard symptoms.hasCoronavirusSymptoms else {
                fatalError()
            }
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: symptoms, startDate: date!))
        case 2:
            guard symptoms.hasCoronavirusSymptoms else {
                fatalError()
            }
            statusState = .checkin(StatusState.Checkin(symptoms: symptoms, checkinDate: date!))
        case 3:
            statusState = .exposed(StatusState.Exposed(startDate: date!))
        case 4:
            statusState = .unexposed(StatusState.Unexposed())
        case 5:
            statusState = .positiveTestResult(StatusState.PositiveTestResult(symptoms: symptoms, startDate: date!))
        case 6:
            statusState = .unclearTestResult(StatusState.UnclearTestResult(symptoms: symptoms, startDate: date!))
        case 7:
            statusState = .negativeTestResult(StatusState.NegativeTestResult(symptoms: symptoms, startDate: date!),
                                                                             nextState: .ok(StatusState.Ok()))
        default:
            fatalError()
        }

        persistence.statusState = statusState
        performSegue(withIdentifier: "unwindFromSetStatusState", sender: self)
    }

}

extension SetStatusStateViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 8
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ["ok", "symptomatic", "checkin", "exposed", "unexposed", "positive test result", "unclear test result", "negative test result"][row]
    }
}

extension SetStatusStateViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let statusState: StatusState
        switch row {
        case 0:
            statusState = .ok(StatusState.Ok())
        case 1:
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: [.temperature, .cough], startDate: Date()))
        case 2:
            statusState = .checkin(StatusState.Checkin(symptoms: [.temperature, .cough], checkinDate: Date()))
        case 3:
            statusState = .exposed(StatusState.Exposed(startDate: Date()))
        case 4:
            statusState = .unexposed(StatusState.Unexposed())
        case 5:
            statusState = .positiveTestResult(StatusState.PositiveTestResult(symptoms: [.temperature, .cough], startDate: Date()))
        case 6:
            statusState = .unclearTestResult(StatusState.UnclearTestResult(symptoms: [.temperature, .cough], startDate: Date()))
        case 7:
            statusState = .negativeTestResult(StatusState.NegativeTestResult(symptoms: [.temperature, .cough], startDate: Date()),
                                              nextState: .ok(StatusState.Ok()))
        default:
            fatalError()
        }

        show(statusState: statusState)
    }
}
