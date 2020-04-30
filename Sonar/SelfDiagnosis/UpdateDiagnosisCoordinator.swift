//
//  UpdateDiagnosisCoordinator.swift
//  Sonar
//
//  Created on 24/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class UpdateDiagnosisCoordinator: Coordinator {
    let navigationController: UINavigationController
    let persisting: Persisting
    let statusViewController: StatusViewController
    let startDate: Date
    
    init(
        navigationController: UINavigationController,
        persisting: Persisting,
        statusViewController: StatusViewController
    ) {
        self.navigationController = navigationController
        self.persisting = persisting
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
            
            self.navigationController.dismiss(animated: true, completion: nil)
            
            if self.symptoms.contains(.temperature) {
                var diagnosis = SelfDiagnosis(symptoms: self.symptoms, startDate: Date())
                diagnosis.expiresIn(days: 1)
                self.persisting.selfDiagnosis = diagnosis
            } else {
                self.persisting.selfDiagnosis = nil
                if self.symptoms.contains(.cough) {
                    self.statusViewController.updatePrompt()
                }
            }
        }
        navigationController.pushViewController(vc, animated: true)
    }
}
