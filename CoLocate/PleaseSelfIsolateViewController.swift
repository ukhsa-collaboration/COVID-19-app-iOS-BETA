//
//  PleaseSelfIsolateViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PleaseSelfIsolateViewController: UIViewController {

    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningViewTitle: UILabel!
    @IBOutlet weak var shareDiagnosisTitle: UILabel!
    @IBOutlet weak var shareDiagnosisBody: UILabel!
    @IBOutlet weak var shareDiagnosisButton: PrimaryButton!
    @IBOutlet weak var moreInformationTitle: UILabel!
    @IBOutlet weak var moreInformationBody: UILabel!

    let contactEventRecorder: ContactEventRecorder = PlistContactEventRecorder.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "NHS Grey 5")
        warningView.backgroundColor = UIColor(named: "NHS Red")
        
        warningViewTitle.text = "You need to isolate yourself and stay at home"
        shareDiagnosisTitle.text = "Help us keep others safe"
        shareDiagnosisBody.text = "This app has recorded all contact you've had with other people using this app over the past 14 days.\n\nSharing this information with the NHS means we can notify these people to take steps to keep themselves safe."
        shareDiagnosisButton.setTitle("Notify", for: .normal)
        moreInformationTitle.text = "Steps you can take"
        moreInformationBody.text = "Based on people you've been in contact with, you may have been exposted to coronavirus.\n\nIf you're on public transport, go home by the most direct route. Stay at least 2 meters away from people if you can. If you're at home:\n\n• Find a room where you can close the door\n\n• Avoid touching people, surfaces and objects\n\nTo keep other people safe, don't visit your GP, pharmacy or hospital"
    }

    @IBAction func didTapNotify(_ sender: Any) {
        let deviceId = UIDevice.current.identifierForVendor!
        let contactEvents = contactEventRecorder.contactEvents
        let request = PatchContactEventsRequest(deviceId: deviceId, contactEvents: contactEvents)

        URLSession.shared.execute(request) { (result) in
            switch result {
            case .success(_):
                print("\(#file).\(#function) SUCCESS !")

                DispatchQueue.main.async {
                    self.present(self.successfulAlert(), animated: true, completion: nil)
                }
            case .failure(let error):
                print("\(#file).\(#function) failure submitting contact events (\(error)) !")

                DispatchQueue.main.async {
                    self.present(self.errorAlert(), animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: - Alert Controllers

    func successfulAlert() -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("Thank you", comment: ""), message: NSLocalizedString("Thank you for sharing your anonymized contact information with us. We will use this information to help inform anyone that may have been in close contact with you recently.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
            alert.dismiss(animated: true)
        }))

        return alert
    }

    func errorAlert() -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("We're sorry, your request could not be handled at this time. Please try again later, so that we can help alert and protect people that you have been in close contact recently", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
            alert.dismiss(animated: true)
        }))

        return alert
    }
}
