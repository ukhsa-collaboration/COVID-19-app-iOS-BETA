//
//  SetStatusStateViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SetStatusStateViewController: UIViewController {

    @IBOutlet weak var statusStateSegmentedControl: UISegmentedControl!
    @IBOutlet weak var temperatureStackView: UIStackView!
    @IBOutlet weak var temperatureSwitch: UISwitch!
    @IBOutlet weak var coughStackView: UIStackView!
    @IBOutlet weak var coughSwitch: UISwitch!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var setStatusStateButton: UIButton!

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
                temperatureStackView.isHidden = true
                return
            }

            temperatureStackView.isHidden = false
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
                coughStackView.isHidden = true
                return
            }

            coughStackView.isHidden = false
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
                dateStackView.isHidden = true
                return
            }

            dateStackView.isHidden = false
            dateButton.setTitle(dateFormatter.string(from: date), for: .normal)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch statusStateMachine.state {
        case .ok:
            statusStateSegmentedControl.selectedSegmentIndex = 0
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
            date = exposed.exposureDate
        }

        statusStateChanged(statusStateSegmentedControl)
    }

    @IBAction func statusStateChanged(_ sender: UISegmentedControl) {
        temperature = nil
        cough = nil
        date = nil
        datePicker.isHidden = true

        switch sender.selectedSegmentIndex {
        case 0:
            setStatusStateButton.setTitle("Set Ok", for: .normal)
        case 1:
            temperature = true
            cough = true
            dateLabel.text = "Start Date"
            date = Date()
            setStatusStateButton.setTitle("Set Symptomatic", for: .normal)
        case 2:
            temperature = true
            cough = true
            dateLabel.text = "Checkin Date"
            date = Date()
            setStatusStateButton.setTitle("Set Checkin", for: .normal)
        case 3:
            date = Date()
            dateLabel.text = "Exposure Date"
            setStatusStateButton.setTitle("Set Exposed", for: .normal)
        default:
            fatalError()
        }
    }

    @IBAction func temperatureChanged(_ sender: UISwitch) {
        temperature = sender.isOn
    }

    @IBAction func coughChanged(_ sender: UISwitch) {
        cough = sender.isOn
    }

    @IBAction func dateButtonPressed(_ sender: UIButton) {
        datePicker.isHidden = false
        if let date = date {
            datePicker.date = date
        }
    }

    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        date = sender.date
    }

    @IBAction func setStatusStateButtonTapped(_ sender: UIButton) {
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
