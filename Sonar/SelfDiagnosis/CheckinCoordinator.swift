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
    let completion: (Symptoms) -> Void
    
    init(
        navigationController: UINavigationController,
        checkin: StatusState.Checkin,
        completion: @escaping (Symptoms) -> Void
    ) {
        self.navigationController = navigationController
        self.checkin = checkin
        self.completion = completion
    }

    var symptoms: Symptoms = []

    func start() {
        let title = hadSymptom(.temperature)
            ? "TEMPERATURE_CHECKIN_QUESTION"
            : "TEMPERATURE_QUESTION"

        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 1,
            pageCount: 3,
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
        let (title, detail) = {
            hadSymptom(.cough)
                ? ("COUGH_CHECKIN_QUESTION", "COUGH_CHECKIN_DETAIL")
                : ("COUGH_QUESTION", "COUGH_DETAIL")
        }()

        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 2,
            pageCount: 3,
            questionTitle: title.localized,
            questionDetail: detail.localized,
            questionError: "COUGH_ERROR".localized,
            questionYes: "COUGH_YES".localized,
            questionNo: "COUGH_NO".localized,
            buttonText: "Continue"
        ) { hasNewCough in
            if hasNewCough {
                self.symptoms.insert(.cough)
            }

            self.openAnosmiaView()
        }

        navigationController.pushViewController(vc, animated: true)
    }
    
    func openAnosmiaView() {
        let title = hadSymptom(.anosmia)
            ? "ANOSMIA_CHECKIN_QUESTION"
            : "ANOSMIA_QUESTION"
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 3,
            pageCount: 3,
            questionTitle: title.localized,
            questionDetail: "ANOSMIA_DETAIL".localized,
            questionError: "ANOSMIA_ERROR".localized,
            questionYes: "ANOSMIA_YES".localized,
            questionNo: "ANOSMIA_NO".localized,
            buttonText: "Submit"
        ) { hasAnosmia in
            if hasAnosmia {
                self.symptoms.insert(.anosmia)
            }

            self.completion(self.symptoms)
        }

        navigationController.pushViewController(vc, animated: true)
    }
    
    private func hadSymptom(_ symptom: Symptom) -> Bool {
        return (checkin.symptoms ?? []).contains(symptom)
    }
}
