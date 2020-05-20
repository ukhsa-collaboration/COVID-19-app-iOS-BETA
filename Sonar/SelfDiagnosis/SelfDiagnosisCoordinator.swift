//
//  SelfDiagnosisCoordinator.swift
//  Sonar
//
//  Created by NHSX on 24/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol Coordinator {
    func start()
}

class SelfDiagnosisCoordinator: Coordinator {
    let navigationController: UINavigationController
    let statusStateMachine: StatusStateMachining
    let completion: (Symptoms) -> Void

    init(
        navigationController: UINavigationController,
        statusStateMachine: StatusStateMachining,
        completion: @escaping (Symptoms) -> Void
    ) {
        self.navigationController = navigationController
        self.statusStateMachine = statusStateMachine
        self.completion = completion
    }
    
    var symptoms = Symptoms()

    static let pageCount = 6
    
    func openQuestionVC(localizedTextPrefix: String,
                          pageNumber: Int,
                          buttonAction: @escaping (Bool) -> Void) {
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: pageNumber,
            pageCount: Self.pageCount,
            questionTitle: "\(localizedTextPrefix)_QUESTION".localized,
            questionDetail: "\(localizedTextPrefix)_DETAIL".localized,
            questionError: "\(localizedTextPrefix)_ERROR".localized,
            questionYes: "\(localizedTextPrefix)_YES".localized,
            questionNo: "\(localizedTextPrefix)_NO".localized,
            buttonText: "Continue",
            buttonAction: buttonAction
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func start() {
        openQuestionVC(localizedTextPrefix: "TEMPERATURE", pageNumber: 1) { hasHighTemperature in
            self.updateSymptoms(with: .temperature, if: hasHighTemperature)
            self.openCoughView()
        }
    }
    
    func openCoughView() {
        openQuestionVC(localizedTextPrefix: "COUGH", pageNumber: 2) { hasNewCough in
            self.updateSymptoms(with: .cough, if: hasNewCough)
            self.openAnosmiaView()
        }
    }
    
    func openAnosmiaView() {
        openQuestionVC(localizedTextPrefix: "ANOSMIA", pageNumber: 3) { hasAnosmia in
            self.updateSymptoms(with: .anosmia, if: hasAnosmia)
            self.openSneezeView()
        }
    }
    
    func openSneezeView() {
        openQuestionVC(localizedTextPrefix: "SNEEZE", pageNumber: 4) { hasSneeze in
            self.updateSymptoms(with: .sneeze, if: hasSneeze)
            self.openNauseaView()
        }
    }
    
    func openNauseaView() {
        openQuestionVC(localizedTextPrefix: "NAUSEA", pageNumber: 5) { hasNausea in
            self.updateSymptoms(with: .nausea, if: hasNausea)
            self.openSubmissionView()
        }
    }

    func openSubmissionView() {
        let vc = SymptomsSummaryViewController.instantiate()
        vc.inject(
            pageNumber: 6,
            symptoms: symptoms,
            statusStateMachine: statusStateMachine,
            completion: completion
        )
        navigationController.pushViewController(vc, animated: true)
    }

    private func updateSymptoms(with symptom: Symptom, if hasSymptom: Bool) {
        if hasSymptom {
            symptoms.insert(symptom)
        } else {
            symptoms.remove(symptom)
        }
    }
}
