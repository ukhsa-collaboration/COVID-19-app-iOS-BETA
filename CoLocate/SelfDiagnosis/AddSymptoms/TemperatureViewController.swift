//
//  TemperatureViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TemperatureViewController: UITableViewController {
    @IBOutlet weak var yesCell: UITableViewCell!
    @IBOutlet weak var noCell: UITableViewCell!

    var continueButton: PrimaryButton?

    var hasHighTemperature: Bool? {
        didSet {
            yesCell.accessoryType = .none
            noCell.accessoryType = .none

            switch hasHighTemperature {
            case .some(true):
                yesCell.accessoryType = .checkmark
            case .some(false):
                noCell.accessoryType = .checkmark
            case .none:
                break
            }

            continueButton?.isEnabled = hasHighTemperature != nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedSectionFooterHeight = 100
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.register(
            ButtonFooterView.nib,
            forHeaderFooterViewReuseIdentifier: ButtonFooterView.reuseIdentifier
        )

        tableView.estimatedSectionHeaderHeight = 100
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.register(
            SymptomQuestionView.nib,
            forHeaderFooterViewReuseIdentifier: SymptomQuestionView.reuseIdentifier
        )
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SymptomQuestionView.reuseIdentifier),
            let symptomQuestionView = view as? SymptomQuestionView else {
                return nil
        }

        symptomQuestionView.titleLabel?.text = "Do you have a high temperature?"
        symptomQuestionView.detailLabel?.text = "I have a high temperature (I feel hot to touch on my chest or back)"

        return symptomQuestionView
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch tableView.cellForRow(at: indexPath) {
        case yesCell:
            hasHighTemperature = true
        case noCell:
            hasHighTemperature = false
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ButtonFooterView.reuseIdentifier),
            let buttonFooterView = view as? ButtonFooterView else {
                return nil
        }

        continueButton = buttonFooterView.button
        continueButton?.isEnabled = false
        continueButton?.setTitle("Continue", for: .normal)
        continueButton?.addTarget(self, action: #selector(continueTapped(_:)), for: .touchUpInside)

        return buttonFooterView
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CoughViewController {
            vc.hasHighTemperature = hasHighTemperature
        }
    }

    @objc private func continueTapped(_ sender: PrimaryButton) {
        sender.isEnabled = false

        performSegue(withIdentifier: "segueToCough", sender: self)
    }
}
