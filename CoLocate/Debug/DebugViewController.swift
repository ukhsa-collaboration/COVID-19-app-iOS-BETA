//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol DebugViewControllerDelegate: class {
    func debugViewControllerWantsToExit(_ sender: DebugViewController) -> Void
}

class DebugViewController: UIViewController {
    
    weak var delegate: DebugViewControllerDelegate?

    @IBAction func clearRegistrationTapped() {
        try! SecureRegistrationStorage.shared.clear()
        DiagnosisService.shared.recordDiagnosis(.unknown)
        show(message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")
    }
    
    @IBAction func clearDiagnosisTapped() {
        DiagnosisService.shared.recordDiagnosis(.unknown)
        show(message: "Diagnosis data has been cleared. Please stop and re-start the application.")
    }
    
    @IBAction func exitTapped() {
        delegate?.debugViewControllerWantsToExit(self)
    }
    
    private func show(message: String) {
        let alertController = UIAlertController(title: "Cleared", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }
}
