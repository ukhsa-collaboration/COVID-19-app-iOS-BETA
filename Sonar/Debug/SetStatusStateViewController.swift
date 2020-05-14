//
//  SetStatusStateViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SetStatusStateViewController: UITableViewController {

    @IBOutlet var statusStateCell: UITableViewCell!
    @IBOutlet var temperatureCell: UITableViewCell!
    @IBOutlet var coughCell: UITableViewCell!
    @IBOutlet var dateCell: UITableViewCell!
    @IBOutlet var datePickerCell: UITableViewCell!

    @IBOutlet weak var statusStateSegmentedControl: UISegmentedControl!
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

    private var symptoms: Set<Symptom> {
        var set: Set<Symptom> = []
        if let temperature = temperature, temperature { set.insert(.temperature) }
        if let cough = cough, cough { set.insert(.cough) }
        return set
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
        [statusStateCell, temperatureCell, coughCell, dateCell, datePickerCell].filter { showCell[$0] ?? false }
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

        if tableView.cellForRow(at: indexPath) == dateCell {
            showCell[datePickerCell] = showCell[datePickerCell].map { !$0 } ?? true
        }
    }

    @IBAction func statusStateChanged(_ sender: UISegmentedControl) {
        let statusState: StatusState
        switch sender.selectedSegmentIndex {
        case 0:
            statusState = .ok(StatusState.Ok())
        case 1:
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: [.temperature, .cough], startDate: Date()))
        case 2:
            statusState = .checkin(StatusState.Checkin(symptoms: [.temperature, .cough], checkinDate: Date()))
        case 3:
            statusState = .exposed(StatusState.Exposed(exposureDate: Date()))
        default:
            fatalError()
        }

        show(statusState: statusState)
    }

    private func show(statusState: StatusState) {
        switch statusState {
        case .ok:
            statusStateSegmentedControl.selectedSegmentIndex = 0
            temperature = nil
            cough = nil
            date = nil
        case .symptomatic(let symptomatic):
            statusStateSegmentedControl.selectedSegmentIndex = 1
            temperature = symptomatic.symptoms.contains(.temperature)
            cough = symptomatic.symptoms.contains(.cough)
            date = symptomatic.startDate
        case .checkin(let checkin):
            statusStateSegmentedControl.selectedSegmentIndex = 2
            temperature = checkin.symptoms.contains(.temperature)
            cough = checkin.symptoms.contains(.cough)
            date = checkin.checkinDate
        case .exposed(let exposed):
            statusStateSegmentedControl.selectedSegmentIndex = 3
            temperature = nil
            cough = nil
            date = exposed.exposureDate
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
        switch statusStateSegmentedControl.selectedSegmentIndex {
        case 0:
            statusState = .ok(StatusState.Ok())
        case 1:
            guard !symptoms.isEmpty else {
                fatalError()
            }
            statusState = .symptomatic(StatusState.Symptomatic(symptoms: symptoms, startDate: date!))
        case 2:
            guard !symptoms.isEmpty else {
                fatalError()
            }
            statusState = .checkin(StatusState.Checkin(symptoms: symptoms, checkinDate: date!))
        case 3:
            statusState = .exposed(StatusState.Exposed(exposureDate: date!))
        default:
            fatalError()
        }

        persistence.statusState = statusState
        performSegue(withIdentifier: "unwindFromSetStatusState", sender: self)
    }

}
