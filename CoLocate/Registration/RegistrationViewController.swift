//
//  RegistrationViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!

    var coordinator: AppCoordinator?
    var session: Session = URLSession.shared
    var registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryButton.setTitle("Register", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO Error handling?
        // TODO (tj) inject these fields
        let maybeRegistration = try? registrationStorage.get()
        if maybeRegistration != nil {
            coordinator?.launchOkNowVC()
        }
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        createRegistration()
    }
    
    private func createRegistration() {
        let request = RequestFactory.registrationRequest()

        session.execute(request, queue: .main) { result in
            self.handleRegistration(result: result)
        }
    }
    
    private func handleRegistration(result: Result<Registration, Error>) {
        self.activityIndicator.stopAnimating()

        switch result {
        case .success(let registration):
            // TODO What do when fail?
            try! registrationStorage.set(registration: registration)

            coordinator?.launchOkNowVC()
        case .failure(let error):
            // TODO Log failure
            print("error during registration: \(error)")
            self.retryButton.isHidden = false
        }
    }
    
}
