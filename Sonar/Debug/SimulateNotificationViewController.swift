//
//  SendNotificationViewController.swift
//  Sonar
//
//  Created by NHSX on 6/2/20
//  Copyright © 2020 NHSX. All rights reserved.
//

#if DEBUG || INTERNAL

import UIKit

fileprivate enum Notification {
    case exposure(Date)
    case testResult(TestResult.ResultType, Date)

    var requiresDate: Bool {
        switch self {
        case .exposure: return true
        case .testResult: return false
        }
    }

    var type: NotificationType {
        switch self {
        case .exposure:
            return .exposure
        case .testResult(.positive, _):
            return .positive
        case .testResult(.negative, _):
            return .negative
        case .testResult(.unclear, _):
            return .unclear
        }
    }

    var date: Date {
        switch self {
        case .exposure(let date):
            return date
        case .testResult(_, let date):
            return date
        }
    }
}

fileprivate enum NotificationType: String, CaseIterable {
    case exposure
    case positive
    case negative
    case unclear
}

class SimulateNotificationViewController: UITableViewController {

    var statusStateMachine: StatusStateMachining!

    func inject(statusStateMachine: StatusStateMachining) {
        self.statusStateMachine = statusStateMachine
    }

    let cellIds = ["type", "typePicker", "datePicker"]

    fileprivate var notification: Notification = .exposure(Date()) {
        didSet { tableView.reloadData() }
    }
    var showTypePicker = false {
        didSet { tableView.reloadData() }
    }

    override public func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)

        // Work around an iOS bug where the right bar button
        // item gets cut off when this is presented modally.
        if #available(iOS 13.0, *) {
          navigationController?.navigationBar.setNeedsLayout()
       }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIds[indexPath.row], for: indexPath)

        switch indexPath.row {
        case 0:
            cell.detailTextLabel?.text = notification.type.rawValue
        default:
            switch cell {
            case let cell as TypePickerCell:
                cell.didSelect = { type in
                    guard type != self.notification.type else { return }

                    switch type {
                    case .exposure:
                        self.notification = .exposure(Date())
                    case .positive:
                        self.notification = .testResult(.positive, Date())
                    case .negative:
                        self.notification = .testResult(.negative, Date())
                    case .unclear:
                        self.notification = .testResult(.unclear, Date())
                    }
                }
            case let cell as DatePickerCell:
                cell.datePicker.date = notification.date
                cell.datePicker.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
            default:
                break
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            showTypePicker = !showTypePicker
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.row, showTypePicker) {
        case (1, false):
            return 0
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    @IBAction func dateChanged(datePicker: UIDatePicker) {
        switch self.notification {
        case .exposure:
            notification = .exposure(datePicker.date)
        case .testResult(let result, _):
            notification = .testResult(result, datePicker.date)
        }
    }

    @IBAction func simulateTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindFromSimulate", sender: self)

        let execute: () -> Void
        switch notification {
        case .exposure(let date):
            execute = { self.statusStateMachine.exposed(on: date) }
        case .testResult(let result, let date):
            execute = {
                let testResult = TestResult(result: result,
                                        testTimestamp: date,
                                        type: nil,
                                        acknowledgementUrl: nil)
                self.statusStateMachine.received(testResult)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: execute)
    }

}

extension SimulateNotificationViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NotificationType.allCases[row].rawValue
    }

}

class TypePickerCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var picker: UIPickerView!
    fileprivate var didSelect: ((NotificationType) -> Void)?

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return NotificationType.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NotificationType.allCases[row].rawValue
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        didSelect?(NotificationType.allCases[row])
    }

}

class DateCell: UITableViewCell {

    @IBOutlet weak var dateSwitch: UISwitch!

    fileprivate var didToggle: ((Bool) -> Void)?

    @IBAction func didToggle(_ sender: UISwitch) {
        self.didToggle?(sender.isOn)
    }

}

class DatePickerCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!

}

#endif
