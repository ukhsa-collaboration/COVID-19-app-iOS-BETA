//
//  SymptomsPromptViewController.swift
//  Sonar
//
//  Created by NHSX on 4/20/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomsPromptViewController: UIViewController, Storyboarded {
    static var storyboardName = "Status"

    var checkin: StatusState.Checkin!
    var statusViewController: StatusViewController!
    var statusStateMachine: StatusStateMachining!

    func inject(
        checkin: StatusState.Checkin!,
        statusViewController: StatusViewController,
        statusStateMachine: StatusStateMachining
    ) {
        self.checkin = checkin
        self.statusViewController = statusViewController
        self.statusStateMachine = statusStateMachine
    }
    
    @IBAction func updateSymptoms(_ sender: Any) {
        let navigationController = UINavigationController()
        let coordinator = CheckinCoordinator(
            navigationController: navigationController,
            checkin: checkin,
            statusViewController: statusViewController,
            statusStateMachine: statusStateMachine
        )
        coordinator.start()
        navigationController.modalPresentationStyle = .fullScreen
        dismiss(animated: true, completion: nil)
        statusViewController.present(navigationController, animated: true)
    }
    
    @IBAction func noSymptoms(_ sender: Any) {
        statusStateMachine.checkin(symptoms: [])
        dismiss(animated: true, completion: nil)
    }
}
