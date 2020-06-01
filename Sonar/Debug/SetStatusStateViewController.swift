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
            temperature = symptomatic.symptoms.map { $0.contains(.temperature) } ?? false
            cough = symptomatic.symptoms.map { $0.contains(.cough) } ?? false
            date = symptomatic.startDate
        case .exposed(let exposed):
            statusLabel.text = "exposed"
            statusPicker.selectRow(2, inComponent: 0, animated: false)
            temperature = nil
            cough = nil
            date = exposed.startDate
        case .positiveTestResult(let positiveTestResult):
            statusLabel.text = "positive test result"
            statusPicker.selectRow(3, inComponent: 0, animated: false)
            temperature = positiveTestResult.symptoms.map { $0.contains(.temperature) } ?? false
            cough = positiveTestResult.symptoms.map { $0.contains(.cough) } ?? false
            date = positiveTestResult.startDate
        case .exposedSymptomatic(let exposedSymptomatic):
            statusLabel.text = "exposed symptomatic"
            statusPicker.selectRow(4, inComponent: 0, animated: false)
            temperature = exposedSymptomatic.symptoms.map { $0.contains(.temperature) } ?? false
            cough = exposedSymptomatic.symptoms.map { $0.contains(.cough) } ?? false
            date = exposedSymptomatic.startDate
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

            let checkinDate = Calendar.current.date(byAdding: .day, value: 1, to: date!)!
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: symptoms, startDate: date!, checkinDate: checkinDate))
        case 2:
            statusState = .exposed(StatusState.Exposed(startDate: date!))
        case 3:
            let checkinDate = Calendar.current.date(byAdding: .day, value: 1, to: date!)!
            statusState = .positiveTestResult(StatusState.PositiveTestResult(checkinDate: checkinDate, symptoms: symptoms, startDate: date!))
        case 4:
            guard symptoms.hasCoronavirusSymptoms else {
                fatalError()
            }

            let checkinDate = Calendar.current.date(byAdding: .day, value: 7, to: date!)!
            statusState = .exposedSymptomatic(StatusState.ExposedSymptomatic(symptoms: symptoms, startDate: date!, checkinDate: checkinDate))
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
        return 5
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ["ok", "symptomatic", "exposed", "positive test result", "exposed symptomatic"][row]
    }
}

extension SetStatusStateViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let statusState: StatusState
        switch row {
        case 0:
            statusState = .ok(StatusState.Ok())
        case 1:
            let startDate = Date()
            let checkinDate = StatusState.Symptomatic.firstCheckin(from: startDate)
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: [.temperature, .cough], startDate: startDate, checkinDate: checkinDate))
        case 2:
            statusState = .exposed(StatusState.Exposed(startDate: Date()))
        case 3:
            let startDate = Date()
            let checkinDate = StatusState.Symptomatic.firstCheckin(from: startDate)
            statusState = .positiveTestResult(StatusState.PositiveTestResult(checkinDate: checkinDate, symptoms: [.temperature, .cough], startDate: Date()))
        case 4:
            let startDate = Date()
            let checkinDate = StatusState.ExposedSymptomatic.firstCheckin(from: startDate)
            statusState = .exposedSymptomatic(StatusState.ExposedSymptomatic(symptoms: [.temperature, .cough], startDate: startDate, checkinDate: checkinDate))
        default:
            fatalError()
        }

        show(statusState: statusState)
    }
}
