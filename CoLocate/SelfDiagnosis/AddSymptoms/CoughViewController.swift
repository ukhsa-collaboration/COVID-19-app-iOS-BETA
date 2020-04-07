//
//  CoughViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CoughViewController: UITableViewController {
    @IBOutlet weak var yesCell: UITableViewCell!
    @IBOutlet weak var noCell: UITableViewCell!

    var continueButton: PrimaryButton?

    var hasHighTemperature: Bool!
    var hasNewCough: Bool? {
        didSet {
            yesCell.accessoryType = .none
            noCell.accessoryType = .none

            switch hasNewCough {
            case .some(true):
                yesCell.accessoryType = .checkmark
            case .some(false):
                noCell.accessoryType = .checkmark
            case .none:
                break
            }

            continueButton?.isEnabled = hasNewCough != nil
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

        symptomQuestionView.titleLabel?.text = "Do you have a new continuous cough?"
        symptomQuestionView.detailLabel?.text = "I have a new continuous cough (I am coughing a lot for more than an hour, or have had 3 or more coughing episodes in 24 hours)"

        return symptomQuestionView
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch tableView.cellForRow(at: indexPath) {
        case yesCell:
            hasNewCough = true
        case noCell:
            hasNewCough = false
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
        if let vc = segue.destination as? SubmitSymptomsViewController {
            vc.hasHighTemperature = hasHighTemperature
            vc.hasNewCough = hasNewCough
        }
    }

    @objc private func continueTapped(_ sender: PrimaryButton) {
        sender.isEnabled = false

        performSegue(withIdentifier: "segueToSubmitSymptoms", sender: self)
    }
}
