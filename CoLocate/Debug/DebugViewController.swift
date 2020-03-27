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
        let alertController = UIAlertController(title: "Cleared", message: "Registration and diagnosis data has been cleared. Please kill and re-start the application.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func exitTapped() {
        delegate?.debugViewControllerWantsToExit(self)
    }
    
}
