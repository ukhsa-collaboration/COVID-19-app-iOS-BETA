//
//  RegistrationViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!
    
    var urlSession: Session!

    func inject(urlSession: Session) {
        self.urlSession = urlSession
    }

    func inject() {
        inject(urlSession: URLSession.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryButton.setTitle("Register", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        createRegistration()
    }
    
    private func createRegistration() {
        let request = RequestFactory.registrationRequest()

        urlSession.execute(request, queue: .main) { result in
            self.handleRegistration(result: result)
        }
    }
    
    private func handleRegistration(result: Result<Registration, Error>) {
        self.activityIndicator.stopAnimating()

        switch result {
        case .success(let registration):
            // TODO What do when fail?
            try! SecureRegistrationStorage.shared.set(registration: registration)

            self.performSegue(withIdentifier: "enterDiagnosisSegue", sender: self)
        case .failure(let error):
            // TODO Log failure
            print("error during registration: \(error)")
            self.retryButton.isHidden = false
        }
    }
    
}
