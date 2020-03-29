//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DebugViewController: UITableViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch indexPath.row {
        case 0:
            try! SecureRegistrationStorage.clear()
            DiagnosisService.shared.recordDiagnosis(.unknown)
            show(message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")
        case 1:
            DiagnosisService.shared.recordDiagnosis(.unknown)
            show(message: "Diagnosis data has been cleared. Please stop and re-start the application.")
        default:
            fatalError()
        }
    }
    
    private func show(message: String) {
        let alertController = UIAlertController(title: "Cleared", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }

}
