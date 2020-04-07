//
//  SubmitSymptomsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SubmitSymptomsViewController: UITableViewController {
//    var requestFactory: SecureRequestFactory?
//    let session: Session = URLSession.shared
//    let contactEventRecorder: ContactEventRecorder = PlistContactEventRecorder.shared

    @IBOutlet weak var hasTemperatureLabel: UILabel!
    @IBOutlet weak var hasCoughLabel: UILabel!

    var hasHighTemperature: Bool!
    var hasNewCough: Bool!

    var submitButton: PrimaryButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        hasTemperatureLabel.text = hasHighTemperature ? "Yes" : "No"
        hasCoughLabel.text = hasNewCough ? "Yes" : "No"

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

        symptomQuestionView.titleLabel?.isHidden = true
        symptomQuestionView.detailLabel?.text = "Thank you for sharing this data with the NHS. We will use this information to anonymously inform people they have come into contact with covid symptoms and encourage them to self-isolate.\n\nThank you for helping us save lives"

        return symptomQuestionView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ButtonFooterView.reuseIdentifier),
            let buttonFooterView = view as? ButtonFooterView else {
                return nil
        }

        submitButton = buttonFooterView.button
        submitButton?.setTitle("Submit", for: .normal)
        submitButton?.addTarget(self, action: #selector(submitTapped(_:)), for: .touchUpInside)

        return buttonFooterView
    }

    @objc private func submitTapped(_ sender: PrimaryButton) {
        sender.isEnabled = false

//        let contactEvents = contactEventRecorder.contactEvents
//
//        guard let request = requestFactory?.patchContactsRequest(contactEvents: contactEvents) else {
//            return
//        }
//
//        session.execute(request, queue: .main) { (result) in
//            switch result {
//            case .success(_):
//                self.present(self.successfulAlert(), animated: true, completion: nil)
//            case .failure(let error):
//                logger.error("failure submitting contact events (\(error)) !")
//
//                self.present(self.errorAlert(), animated: true, completion: nil)
//            }
//        }
    }
}
