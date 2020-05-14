//
//  CheckinCoordinator.swift
//  Sonar
//
//  Created by NHSX on 24/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CheckinCoordinator: Coordinator {
    let navigationController: UINavigationController
    let checkin: StatusState.Checkin
    let statusViewController: StatusViewController
    var statusStateMachine: StatusStateMachining
    
    init(
        navigationController: UINavigationController,
        checkin: StatusState.Checkin,
        statusViewController: StatusViewController,
        statusStateMachine: StatusStateMachining
    ) {
        self.navigationController = navigationController
        self.checkin = checkin
        self.statusViewController = statusViewController
        self.statusStateMachine = statusStateMachine
    }
    
    var symptoms = Set<Symptom>()
    
    func start() {
        let title = checkin.symptoms.contains(.temperature)
            ? "TEMPERATURE_CHECKIN_QUESTION"
            : "TEMPERATURE_QUESTION"

        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 1,
            pageCount: 2,
            questionTitle: title.localized,
            questionDetail: "TEMPERATURE_DETAIL".localized,
            questionError: "TEMPERATURE_ERROR".localized,
            questionYes: "TEMPERATURE_YES".localized,
            questionNo: "TEMPERATURE_NO".localized,
            buttonText: "Continue"
        ) { hasHighTemperature in
            if hasHighTemperature {
                self.symptoms.insert(.temperature)
            }
            self.openCoughView()
        }

        navigationController.pushViewController(vc, animated: true)
    }
    
    func openCoughView() {
        let (title, details) = {
            checkin.symptoms.contains(.cough)
            ? ("COUGH_CHECKIN_QUESTION", ["COUGH_CONTINUOUS_DETAIL"])
            : ("COUGH_QUESTION", ["COUGH_NEW_DETAIL", "COUGH_CONTINUOUS_DETAIL"])
        }()

        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 2,
            pageCount: 2,
            questionTitle: title.localized,
            questionDetail: details.map { $0.localized }.joined(separator: ""),
            questionError: "COUGH_ERROR".localized,
            questionYes: "COUGH_YES".localized,
            questionNo: "COUGH_NO".localized,
            buttonText: "Submit"
        ) { hasNewCough in
            if hasNewCough {
                self.symptoms.insert(.cough)
            }
            
            self.navigationController.dismiss(animated: true, completion: nil)

            self.statusStateMachine.checkin(symptoms: self.symptoms)

            if case .ok = self.statusStateMachine.state {
                self.statusViewController.updatePrompt()
            }
        }

        navigationController.pushViewController(vc, animated: true)
    }
}
