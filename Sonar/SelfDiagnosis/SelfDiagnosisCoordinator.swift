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
    let completion: (Set<Symptom>) -> Void

    init(
        navigationController: UINavigationController,
        statusStateMachine: StatusStateMachining,
        completion: @escaping (Set<Symptom>) -> Void
    ) {
        self.navigationController = navigationController
        self.statusStateMachine = statusStateMachine
        self.completion = completion
    }
    
    var symptoms = Set<Symptom>()

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
            if hasHighTemperature { self.symptoms.insert(.temperature) }
            self.openCoughView()
        }
    }
    
    func openCoughView() {
        openQuestionVC(localizedTextPrefix: "COUGH", pageNumber: 2) { hasNewCough in
            if hasNewCough { self.symptoms.insert(.cough) }
            self.openSmellView()
        }
    }
    
    func openSmellView() {
        openQuestionVC(localizedTextPrefix: "SMELL", pageNumber: 3) { hasSmellLoss in
            if hasSmellLoss { self.symptoms.insert(.smellLoss) }
            self.openFeverView()
        }
    }
    
    func openFeverView() {
        openQuestionVC(localizedTextPrefix: "FEVER", pageNumber: 4) { hasFever in
            if hasFever { self.symptoms.insert(.fever) }
            self.openNauseaView()
        }
    }
    
    func openNauseaView() {
        openQuestionVC(localizedTextPrefix: "NAUSEA", pageNumber: 5) { hasNausea in
            if hasNausea { self.symptoms.insert(.nausea) }
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
}
