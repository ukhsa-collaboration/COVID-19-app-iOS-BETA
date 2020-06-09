//
//  SetStatusStateViewController.swift
//  Sonar
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL
fileprivate enum CellConfig {
    case state(String, (String) -> Void)
    case date(String, Date, (Date) -> Void)
    case symptoms(Symptoms?, (Symptoms?) -> Void)

    private var identifier: String {
        switch self {
        case .state: return "state"
        case .date: return "date"
        case .symptoms: return "symptoms"
        }
    }

    func cell(for tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        switch self {
        case .state(let state, let didSelect):
            let cell = cell as! StateCell
            cell.stateLabel.text = state
            cell.didSelect = didSelect
        case .date(let title, let date, let didSelect):
            let cell = cell as! StatusStateDateCell
            cell.titleLabel.text = title
            cell.date = date
            cell.didSelect = didSelect
        case .symptoms(let symptoms, let didSelect):
            let cell = cell as! SymptomsCell
            if let symptoms = symptoms {
                cell.symptomsSwitch.isOn = true
                cell.symptomViews.forEach { $0.isHidden = false }
                for (sw, sy) in zip(cell.symptomSwitches, Symptom.allCases) {
                    sw.isOn = symptoms.contains(sy)
                }
            } else {
                cell.symptomsSwitch.isOn = false
                cell.symptomViews.forEach { $0.isHidden = true }
            }
            cell.didSelect = didSelect
        }
        return cell
    }

}

class SetStatusStateViewController: UITableViewController {

    var persistence: Persisting!

    var state: StatusState! {
        didSet { tableView.reloadData() }
    }

    fileprivate var cellConfigs: [CellConfig] {
        switch state! {
        case .ok:
            return [.state("ok", setState)]
        case .symptomatic(let symptomatic):
            return [
                .state("symptomatic", setState),
                .date("Start Date", symptomatic.startDate, { date in
                    self.state = .symptomatic(StatusState.Symptomatic(
                        symptoms: symptomatic.symptoms,
                        startDate: date,
                        checkinDate: symptomatic.checkinDate
                    ))
                }),
                .date("Checkin Date", symptomatic.checkinDate, { date in
                    self.state = .symptomatic(StatusState.Symptomatic(
                        symptoms: symptomatic.symptoms,
                        startDate: symptomatic.startDate,
                        checkinDate: date
                    ))
                }),
                .symptoms(symptomatic.symptoms, { symptoms in
                    self.state = .symptomatic(StatusState.Symptomatic(
                        symptoms: symptoms,
                        startDate: symptomatic.startDate,
                        checkinDate: symptomatic.checkinDate
                    ))
                }),
            ]
        case .exposed(let exposed):
            return [
                .state("exposed", setState),
                .date("Start Date", exposed.startDate, {
                    self.state = .exposed(StatusState.Exposed(startDate: $0))
                }),
            ]
        case .positive(let positive):
            return [
                .state("positive", setState),
                .date("Start Date", positive.startDate, { date in
                    self.state = .positive(StatusState.Positive(
                        checkinDate: positive.checkinDate,
                        symptoms: positive.symptoms,
                        startDate: date
                    ))
                }),
                .date("Checkin Date", positive.checkinDate, { date in
                    self.state = .positive(StatusState.Positive(
                        checkinDate: date,
                        symptoms: positive.symptoms,
                        startDate: positive.startDate
                    ))
                }),
                .symptoms(positive.symptoms, { symptoms in
                    self.state = .positive(StatusState.Positive(
                        checkinDate: positive.checkinDate,
                        symptoms: symptoms,
                        startDate: positive.startDate
                    ))
                }),
            ]
        case .exposedSymptomatic(let exposedSymptomatic):
            return [
                .state("exposed symptomatic", setState),
                .date("Exposed Start Date", exposedSymptomatic.startDate, { date in
                    self.state = .exposedSymptomatic(StatusState.ExposedSymptomatic(
                        exposed: StatusState.Exposed(startDate: date),
                        symptoms: exposedSymptomatic.symptoms,
                        startDate: exposedSymptomatic.startDate,
                        checkinDate: exposedSymptomatic.checkinDate
                    ))
                }),
                .date("Start Date", exposedSymptomatic.startDate, { date in
                    self.state = .exposedSymptomatic(StatusState.ExposedSymptomatic(
                        exposed: exposedSymptomatic.exposed,
                        symptoms: exposedSymptomatic.symptoms,
                        startDate: date,
                        checkinDate: exposedSymptomatic.checkinDate
                    ))
                }),
                .date("Checkin Date", exposedSymptomatic.checkinDate, { date in
                    self.state = .exposedSymptomatic(StatusState.ExposedSymptomatic(
                        exposed: exposedSymptomatic.exposed,
                        symptoms: exposedSymptomatic.symptoms,
                        startDate: exposedSymptomatic.startDate,
                        checkinDate: date
                    ))
                }),
                .symptoms(exposedSymptomatic.symptoms, { symptoms in
                    self.state = .exposedSymptomatic(StatusState.ExposedSymptomatic(
                        exposed: exposedSymptomatic.exposed,
                        symptoms: symptoms,
                        startDate: exposedSymptomatic.startDate,
                        checkinDate: exposedSymptomatic.checkinDate
                    ))
                }),
            ]
        }
    }

    override func viewDidLoad() {
        state = persistence.statusState
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellConfigs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellConfigs[indexPath.row].cell(for: tableView)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case let cell as StateCell:
            cell.showPicker = !cell.showPicker
            tableView.reloadData()
        case let cell as StatusStateDateCell:
            cell.showPicker = !cell.showPicker
            tableView.reloadData()
        default:
            break
        }
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        persistence.statusState = state
        performSegue(withIdentifier: "unwindFromSetStatusState", sender: self)
    }

    private func setState(_ state: String) {
        switch state {
        case "ok":
            self.state = .ok(StatusState.Ok())
        case "symptomatic":
            self.state = .symptomatic(StatusState.Symptomatic(symptoms: nil, startDate: Date(), checkinDate: Date()))
        case "exposed":
            self.state = .exposed(StatusState.Exposed(startDate: Date()))
        case "positive":
            self.state = .positive(StatusState.Positive(checkinDate: Date(), symptoms: nil, startDate: Date()))
        case "exposed symptomatic":
            self.state = .exposedSymptomatic(StatusState.ExposedSymptomatic(
                exposed: StatusState.Exposed(startDate: Date()),
                symptoms: nil,
                startDate: Date(),
                checkinDate: Date()
            ))
        default:
            assertionFailure("invalid state: \(state)")
        }
    }

}

class StateCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    let states = ["ok", "symptomatic", "exposed", "positive", "exposed symptomatic"]

    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!

    var showPicker = false {
        didSet { picker.isHidden = !showPicker }
    }
    var didSelect: ((String) -> Void)?

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return states.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return states[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        didSelect?(states[row])
    }

}

class StatusStateDateCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!

    var showPicker = false {
        didSet { datePicker.isHidden = !showPicker }
    }
    var date: Date! {
        didSet { dateLabel.text = dateFormatter.string(from: date) }
    }
    var didSelect: ((Date) -> Void)?

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        didSelect?(sender.date)
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

}

class SymptomsCell: UITableViewCell {

    @IBOutlet weak var symptomsSwitch: UISwitch!

    @IBOutlet var symptomViews: [UIStackView]!
    @IBOutlet var symptomLabels: [UILabel]!
    @IBOutlet var symptomSwitches: [UISwitch]!

    var didSelect: ((Symptoms?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        for (l, s) in zip(symptomLabels, Symptom.allCases) {
            l.text = s.rawValue
        }
    }

    @IBAction func toggleSymptoms(_ sender: UISwitch) {
        if sender.isOn {
            didSelect?([])
        } else {
            didSelect?(nil)
        }
    }

    @IBAction func toggleSymptom(_ sender: UISwitch) {
        var symptoms: Symptoms = []
        for (sw, sy) in zip(symptomSwitches, Symptom.allCases) {
            if sw.isOn {
                symptoms.insert(sy)
            }
        }
        didSelect?(symptoms)
    }

}

#endif
