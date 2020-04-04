//
//  PermissionsDeniedViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PermissionsDeniedViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    let authManager = AuthorizationManager()

    @IBOutlet weak var bluetoothLabel: UILabel!
    @IBOutlet weak var notificationsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bluetoothLabel.text = "Bluetooth: \(authManager.bluetooth)"
        authManager.notifications { status in
            DispatchQueue.main.async {
                self.notificationsLabel.text = "Notifications: \(status)"
            }
        }
    }

    @IBAction func settingsTapped(_ sender: UIButton) {
        let app = UIApplication.shared
        app.open(
            URL(string: UIApplication.openSettingsURLString)!,
            options: [:]
        ) { [weak self] _ in
            self?.performSegue(withIdentifier: "unwindFromPermissionsDenied", sender: self)
        }
    }
}
