//
//  SubmitSymptomsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class SubmitSymptomsViewController: UIViewController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    private var persistence: Persisting!
    private var contactEventRepository: ContactEventRepository!
    private var session: Session!
    private var hasHighTemperature: Bool!
    private var hasNewCough: Bool!
    private var isSubmitting = false
    
    private var hasSymptoms: Bool {
        hasHighTemperature || hasNewCough
    }

    func inject(persistence: Persisting, contactEventRepository: ContactEventRepository, session: Session, hasHighTemperature: Bool, hasNewCough: Bool) {
        self.persistence = persistence
        self.contactEventRepository = contactEventRepository
        self.session = session
        self.hasHighTemperature = hasHighTemperature
        self.hasNewCough = hasNewCough
    }
    
    @IBOutlet weak var summary: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        summary.text = "QUESTION_SUMMARY".localized
    }
    
    @IBAction func submitTapped(_ sender: PrimaryButton) {
        guard let registration = persistence.registration else {
            fatalError("What do we do when we aren't registered?")
        }

        guard hasSymptoms else {
            self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
            return
        }
        
        guard !isSubmitting else { return }
        isSubmitting = true
        
        // NOTE: This is not spec'ed out, and is only here
        // so we can make sure this flow works through the
        // app during debugging. This will need to be replaced
        // with real business logic in the future.
        persistence.diagnosis = .infected
        
        let requestFactory = ConcreteSecureRequestFactory(registration: registration)
        let request = requestFactory.patchContactsRequest(contactEvents: contactEventRepository.contactEvents)
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self else { return }
            
            self.isSubmitting = false

            switch result {
            case .success(_):
                self.performSegue(withIdentifier: "unwindFromSelfDiagnosis", sender: self)
                self.contactEventRepository.reset()
            case .failure(let error):
                self.alert(error: error)
            }
        }
    }

    private func alert(error: Error) {
        let alert = UIAlertController(
            title: nil,
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

fileprivate let logger = Logger(label: "SelfDiagnosis")
