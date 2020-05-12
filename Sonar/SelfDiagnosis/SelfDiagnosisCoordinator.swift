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
    let persisting: Persisting
    let contactEventsUploader: ContactEventsUploading
    let statusViewController: StatusViewController
    let statusStateMachine: StatusStateMachining
    let localNotificationScheduler: Scheduler
    
    init(
        navigationController: UINavigationController,
        persisting: Persisting,
        contactEventsUploader: ContactEventsUploading,
        statusViewController: StatusViewController,
        statusStateMachine: StatusStateMachining,
        localNotificationScheduler: Scheduler
    ) {
        self.navigationController = navigationController
        self.persisting = persisting
        self.contactEventsUploader = contactEventsUploader
        self.statusViewController = statusViewController
        self.statusStateMachine = statusStateMachine
        self.localNotificationScheduler = localNotificationScheduler
    }
    
    var hasHighTemperature: Bool!
    var hasNewCough: Bool!
    
    func start() {
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 1,
            pageCount: 3,
            questionTitle: "TEMPERATURE_QUESTION".localized,
            questionDetail: "TEMPERATURE_DETAIL".localized,
            questionError: "TEMPERATURE_ERROR".localized,
            questionYes: "TEMPERATURE_YES".localized,
            questionNo: "TEMPERATURE_NO".localized,
            buttonText: "Continue"
        ) { hasHighTemperature in
            self.hasHighTemperature = hasHighTemperature
            self.openCoughView()
        }
        navigationController.pushViewController(vc, animated: true)
    }
    
    func openCoughView() {
        let vc = QuestionSymptomsViewController.instantiate()
        vc.inject(
            pageNumber: 2,
            pageCount: 3,
            questionTitle: "COUGH_QUESTION".localized,
            questionDetail: "COUGH_NEW_DETAIL".localized + "COUGH_CONTINUOUS_DETAIL".localized,
            questionError: "COUGH_ERROR".localized,
            questionYes: "COUGH_YES".localized,
            questionNo: "COUGH_NO".localized,
            buttonText: "Continue"
        ) { hasNewCough in
            self.hasNewCough = hasNewCough
            self.openSubmissionView()
        }
        navigationController.pushViewController(vc, animated: true)
    }
    
    func openSubmissionView() {
        let vc = SymptomsSummaryViewController.instantiate()
        vc.inject(
            persisting: persisting,
            contactEventsUploader: contactEventsUploader,
            hasHighTemperature: hasHighTemperature,
            hasNewCough: hasNewCough,
            statusViewController: statusViewController,
            statusStateMachine: statusStateMachine,
            localNotificationScheduler: localNotificationScheduler
        )
        navigationController.pushViewController(vc, animated: true)
    }
}
