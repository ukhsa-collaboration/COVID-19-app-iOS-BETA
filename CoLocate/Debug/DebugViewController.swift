//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DebugViewController: UITableViewController {

    let persistance = Persistance.shared
    @IBOutlet weak var interceptRequestsSwitch: UISwitch!

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            persistance.clear()
            show(title: "Cleared", message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")

        case (0, 1):
            let alertController = UIAlertController(title: "Set diagnosis", message: nil, preferredStyle: .actionSheet)
            for diagnosis in Diagnosis.allCases {
                alertController.addAction(UIAlertAction(title: "\(diagnosis)", style: .default) { _ in
                    Persistance.shared.diagnosis = diagnosis
                    self.show(title: "Cleared", message: "Diagnosis data has been set. Please stop and re-start the application.")
                })
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true, completion: nil)

        case (1, 0):
            PlistContactEventRecorder.shared.record(ContactEvent(remoteContactId: UUID(), rssi: 42))
            PlistContactEventRecorder.shared.record(ContactEvent(remoteContactId: UUID(), rssi: 17))
            PlistContactEventRecorder.shared.record(ContactEvent(remoteContactId: UUID(), rssi: -2))
            show(title: "Events Recorded", message: "Dummy contact events have been recorded locally (but not sent to the server.)")
            
        case (1, 1):
            PlistContactEventRecorder.shared.reset()
            show(title: "Cleared", message: "All contact events cleared.")
            
        case (2, 0):
            do {
                guard let registration = persistance.registration else {
                    throw NSError()
                }
                let delay = 15
                let request = TestPushRequest(key: registration.secretKey, sonarId: registration.id, delay: delay)
                URLSession.shared.execute(request, queue: .main) { result in
                    switch result {
                    case .success:
                        self.show(title: "Push scheduled", message: "Scheduled push with \(delay) second delay")
                    case .failure(let error):
                        self.show(title: "Failed", message: "Failed scheduling push: \(error)")
                    }
                }
            } catch {
                show(title: "Failed", message: "Couldn't get sonarId, has this device completed registration?")
            }

        default:
            fatalError()
        }
    }

    private func show(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func interceptRegistrationRequestsChanged(_ sender: UISwitch) {
    }
}

class TestPushRequest: SecureRequest, Request {
    
    typealias ResponseType = Void
                    
    let method: HTTPMethod
    
    let path: String
    
    init(key: Data, sonarId: UUID, delay: Int = 0) {
        let data = Data()
        method = .post(data: data)
        path = "/api/debug/notification/residents/\(sonarId.uuidString)?delay=\(delay)"
        
        super.init(key, data, [:])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
}
