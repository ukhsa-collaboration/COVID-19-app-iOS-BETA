//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL
class DebugViewController: UITableViewController, Storyboarded {
    static let storyboardName = "Debug"

    @IBOutlet weak var allowedDataSharingSwitch: UISwitch!
    @IBOutlet weak var versionBuildLabel: UILabel!
    @IBOutlet weak var potentiallyExposedSwitch: UISwitch!
    @IBOutlet weak var enableNewSelfDiagnosis: UISwitch!

    private var persistence: Persisting!
    private var contactEventRepository: ContactEventRepository!
    
    func inject(persistence: Persisting, contactEventRepository: ContactEventRepository) {
        self.persistence = persistence
        self.contactEventRepository = contactEventRepository
    }
    
    override func viewDidLoad() {
        potentiallyExposedSwitch.isOn = persistence.potentiallyExposed
        allowedDataSharingSwitch.isOn = persistence.allowedDataSharing

        let build = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown"
        versionBuildLabel.text = "Version \(version) (build \(build))"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            persistence.clear()
            try! SecureBroadcastRotationKeyStorage().clear()
            show(title: "Cleared", message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")

        case (0, 1):
            break

        case (0, 2), (0, 3):
            break

        case (1, 0):
            show(title: "Whoops!", message: "No dummy events recorded, this functionality temporarily disabled!")
            
        case (1, 1):
            contactEventRepository.reset()
            show(title: "Cleared", message: "All contact events cleared.")
            
        case (2, 0):
            do {
                guard let registration = persistence.registration else {
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

        case (3, 0):
            #if DEBUG
            let info = Bundle(for: AppDelegate.self).infoDictionary!
            let id = info["DEBUG_REGISTRATION_ID"] as! String
            let secretKey = info["DEBUG_REGISTRATION_SECRET_KEY"] as! String
            persistence.registration = Registration(id: UUID(uuidString: id)!, secretKey: secretKey.data(using: .utf8)!)
            #else
            let alert = UIAlertController(title: "Unavailable", message: "This dangerous action is only available in debug builds.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            #endif

        case (4, 0):
            do {
                let fileManager = FileManager()
                let documentsFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let viewController = UIActivityViewController(activityItems: [documentsFolder], applicationActivities: nil)
                present(viewController, animated: true, completion: nil)
            } catch {
                let viewController = UIAlertController(title: "No data to share yet", message: nil, preferredStyle: .alert)
                viewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(viewController, animated: true, completion: nil)
            }

        case (5, 0):
            break

        default:
            fatalError()
        }
    }

    private func show(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func potentiallyExposedChanged(_ sender: UISwitch) {
        persistence.potentiallyExposed = sender.isOn
    }

    @IBAction func allowedDataSharingChanged(_ sender: UISwitch) {
        persistence.allowedDataSharing = sender.isOn
    }

    @IBAction func enableNewKeyRotation(_ sender: UISwitch) {
        persistence.enableNewKeyRotation = sender.isOn
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as SetDiagnosisViewController:
            vc.inject(persistence: persistence)
        default:
            break
        }
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
#endif
