//
//  RegistrationViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController, Storyboarded {
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var retryButton: UIButton!

    var coordinator: AppCoordinator?
    var session: Session = URLSession.shared
    var registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared
    var notificationManager: NotificationManager!
    
    func inject(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        retryButton.setTitle("Register", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.notificationManager.delegate = self

        // TODO Error handling?
        let maybeRegistration = try? registrationStorage.get()
        if maybeRegistration != nil {
            coordinator?.launchOkNowVC()
        }
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        let request = RequestFactory.registrationRequest(pushToken: notificationManager.pushToken!)

        session.execute(request, queue: .main) { result in
            self.handleRegistration(result: result)
        }
    }
    
    private func handleRegistration(result: Result<(), Error>) {
        self.activityIndicator.stopAnimating()

        switch result {
        case .success(_):
            // TODO What do when fail?
            print("First registration request succeeded")

            coordinator?.launchOkNowVC()
        case .failure(let error):
            // TODO Log failure
            print("error during registration: \(error)")
            self.retryButton.isHidden = false
        }
    }
}

extension RegistrationViewController : NotificationManagerDelegate {
    func notificationManager(_ notificationManager: NotificationManager, didObtainPushToken token: String) {
    }
    
    func notificationManager(
        _ notificationManager: NotificationManager,
        didReceiveNotificationWithInfo userInfo: [AnyHashable : Any]
    ) {
        guard let activationCode = userInfo["activationCode"] as? String else { return }
        
        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode, pushToken: notificationManager.pushToken!)
        session.execute(request, queue: .main) { [weak self] result in
            // TODO: Probably need to save the registration somewhere
            self?.coordinator?.launchEnterDiagnosis()
        }
    }

}
