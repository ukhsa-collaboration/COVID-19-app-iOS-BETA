//
//  NotificationsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class NotificationsPromptViewController : UIViewController, Storyboarded {
    static let storyboardName = "Notifications"
    
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var bodyCopy: UILabel!
    @IBOutlet weak var continueButton: PrimaryButton!

    var uiQueue: DispatchQueue = DispatchQueue.main
    var pushNotificationsRequester: PushNotificationRequester?

    override func viewDidLoad() {
        super.viewDidLoad()

        headlineLabel.text = "Push Notifications"
        bodyCopy.text = """
        In order to alert you when you have been in close contact with someone that has been diagnosed with Coronavirus, this application requires push notifications.
        """

        continueButton.setTitle("I understand", for: .normal)
    }

    @IBAction func didTapContinue(_ sender: Any) {
        pushNotificationsRequester?.requestPushNotifications() { [weak self] result in
            self?.uiQueue.sync {
                self?.handleNotifications(result: result)
            }
        }
    }

    private func handleNotifications(result: Result<Bool, Error>) {
        switch result {
        case .success(true):
            self.pushNotificationsRequester?.advanceAfterPushNotifications()
        default:
            // TODO
            print("user did not accept notifications")
        }
    }
}
