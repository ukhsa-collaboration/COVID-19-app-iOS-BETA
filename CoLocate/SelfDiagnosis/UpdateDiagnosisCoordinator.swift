//
//  UpdateDiagnosisCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class UpdateDiagnosisCoordinator: Coordinator {
    let navigationController: UINavigationController
    let persisting: Persisting
    let session: Session
    let statusViewController: StatusViewController
    let startDate: Date
    
    init(
        navigationController: UINavigationController,
        persisting: Persisting,
        statusViewController: StatusViewController,
        session: Session
    ) {
        self.navigationController = navigationController
        self.persisting = persisting
        self.session = session
        self.statusViewController = statusViewController
        startDate = persisting.selfDiagnosis?.startDate ?? Date()
    }
    
    var symptoms = Set<Symptom>()
    
    func start() {
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 1,
            pageCount: 2,
            questionTitle: "TEMPERATURE_QUESTION".localized,
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
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 2,
            pageCount: 2,
            questionTitle: "COUGH_QUESTION".localized,
            questionDetail: "COUGH_DETAIL".localized,
            questionError: "COUGH_ERROR".localized,
            questionYes: "COUGH_YES".localized,
            questionNo: "COUGH_NO".localized,
            buttonText: "Submit"
        ) { hasNewCough in
            if hasNewCough {
                self.symptoms.insert(.cough)
            }
            self.persisting.selfDiagnosis = SelfDiagnosis(symptoms: self.symptoms, startDate: self.startDate)
            self.navigationController.dismiss(animated: true, completion: nil)
        }
        navigationController.pushViewController(vc, animated: true)
    }
}
