//
//  StatusViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController, Storyboarded {
    static let storyboardName = "Status"

    var persistence = Persistence.shared
    
    @IBOutlet private var warningView: UIView!
    @IBOutlet private var warningViewTitle: UILabel!
    @IBOutlet private var warningViewBody: UILabel!
    @IBOutlet private var checkSymptomsTitle: UILabel!
    @IBOutlet private var checkSymptomsBody: UILabel!
    @IBOutlet private var moreInformationTitle: UILabel!
    @IBOutlet private var moreInformationBody: UILabel!
    @IBOutlet private var checkSymptomsButton: PrimaryButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "NHS Grey 5")
    
        warningView.backgroundColor = UIColor(named: "NHS Purple")
        
        warningViewTitle.text = "OK_NOW_TITLE".localized
        warningViewBody.text = "OK_NOW_MESSAGE".localized
        checkSymptomsTitle.text = "OK_NOW_SYMPTOMS_TITLE".localized
        checkSymptomsBody.text = "OK_NOW_SYMPTOMS_MESSAGE".localized
        checkSymptomsButton.setTitle("OK_NOW_SYMPTOMS_BUTTON".localized, for: .normal)
        moreInformationTitle.text = "OK_NOW_MORE_INFO_TITLE".localized
        moreInformationBody.text = "OK_NOW_MORE_INFO_MESSAGE".localized
    }
    
    @IBAction func checkSymptomsTapped(_ sender: PrimaryButton) {
        if persistence.enableNewSelfDiagnosis {
            let selfDiagnosis = SelfDiagnosisNavigationController.instantiate()
            present(selfDiagnosis, animated: true)
        } else {
            let enterDiagnosisVC = EnterDiagnosisTableViewController.instantiate()
            (parent as! RootViewController).show(viewController: enterDiagnosisVC)
        }
    }

    @IBAction func unwindFromOnboarding(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }

    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)
    }
}

