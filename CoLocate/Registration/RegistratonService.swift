//
//  RegistratonService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol RegistrationService {
    func register(completionHandler: @escaping ((Result<(), Error>) -> Void))
}

class ConcreteRegistrationService: RegistrationService {
    var session: Session
    var registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared
    var notificationManager: NotificationManager
    var registerWhenTokenReceived = false
    var completionHandler: ((Result<(), Error>) -> Void)?
    
    init(session: Session, notificationManager: NotificationManager) {
        self.session = session
        self.notificationManager = notificationManager
    }
    
    func register(completionHandler: @escaping ((Result<(), Error>) -> Void)) {
        self.completionHandler = completionHandler
        notificationManager.delegate = self

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
    
    private func handleRegistration(result: Result<(), Error>) {
        switch result {
        case .success(_):
            // TODO What do when fail?
            print("First registration request succeeded")

        case .failure(let error):
            // TODO How do we handle this failure?
            print("error during registration: \(error)")
            completionHandler!(.failure(error))
        }
    }
    
    private func succeed() {
        notificationManager.delegate = nil
        completionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        notificationManager.delegate = nil
        completionHandler?(.failure(error))
    }
}


extension ConcreteRegistrationService: NotificationManagerDelegate {
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
                    self.fail(withError: error)
                }
                 
                self.succeed()
                
            case .failure(let error):
                // TODO How do we handle this failure?
                print("error during registration: \(error)")
                    self.fail(withError: error)
            }
        }
    }

}
