//
//  SymptomsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SymptomsPromptViewController: UIViewController, Storyboarded {
    static var storyboardName = "Status"
    var persistence: Persisting!
    var session: Session!
        
    func inject(persistence: Persisting, session: Session) {
        self.persistence = persistence
        self.session = session
    }
    
    @IBAction func updateSymptoms(_ sender: Any) {
        let navigationController = UINavigationController()
        let coordinator = UpdateDiagnosisCoordinator(
            navigationController: navigationController,
            persisting: persistence,
            session: session
        )
        coordinator.start()
        navigationController.modalPresentationStyle = .fullScreen
        dismiss(animated: true, completion: nil)
        present(navigationController, animated: true)
    }
    
    @IBAction func noSymptoms(_ sender: Any) {
        persistence.selfDiagnosis = nil
        dismiss(animated: true, completion: nil)
    }
}
