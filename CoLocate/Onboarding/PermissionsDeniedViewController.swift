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
