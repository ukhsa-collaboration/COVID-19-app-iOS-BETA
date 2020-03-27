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
    var registerWhenTokenReceived = false
    
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
        if notificationManager.pushToken == nil {
            registerWhenTokenReceived = true
            return
        } else {
            beginRegistration()
        }
    }
    
    private func beginRegistration() {
        let request = RequestFactory.registrationRequest(pushToken: notificationManager.pushToken!)

        session.execute(request, queue: .main) { result in
            self.handleRegistration(result: result)
        }

    }
    
    private func enableRetry() {
        self.retryButton.isHidden = false
        self.activityIndicator.stopAnimating()
    }
    
    private func handleRegistration(result: Result<(), Error>) {
        switch result {
        case .success(_):
            // TODO What do when fail?
            print("First registration request succeeded")

        case .failure(let error):
            // TODO How do we handle this failure?
            print("error during registration: \(error)")
            self.enableRetry()
        }
    }
}

extension RegistrationViewController : NotificationManagerDelegate {
    func notificationManager(_ notificationManager: NotificationManager, didObtainPushToken token: String) {
        if registerWhenTokenReceived {
            beginRegistration()
        }
    }
    
    func notificationManager(
        _ notificationManager: NotificationManager,
        didReceiveNotificationWithInfo userInfo: [AnyHashable : Any]
    ) {
        guard let activationCode = userInfo["activationCode"] as? String else { return }
        
        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode, pushToken: notificationManager.pushToken!)
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let registration = Registration(id: response.id, secretKey: response.secretKey)
                
                do {
                    try self.registrationStorage.set(registration: registration)
                } catch {
                    print("Error saving registration: \(error)")
                    self.enableRetry()
                }
                
                self.coordinator?.launchEnterDiagnosis()
                
            case .failure(let error):
                // TODO How do we handle this failure?
                print("error during registration: \(error)")
                self.enableRetry()
            }
        }
    }

}
