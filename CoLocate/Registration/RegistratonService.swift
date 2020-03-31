//
//  RegistratonService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol RegistrationService {
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void))
}

let RegistrationCompleteNotification = NSNotification.Name("RegistrationCompleteNotification")
let RegistrationCompleteNotificationRegistrationKey = "registration"

class ConcreteRegistrationService: RegistrationService {
    let session: Session
    let registrationStorage: SecureRegistrationStorage = SecureRegistrationStorage.shared
    var notificationManager: NotificationManager
    let notificationCenter: NotificationCenter
    var registerWhenTokenReceived = false
    var completionHandler: ((Result<Void, Error>) -> Void)?
    
    init(session: Session, notificationManager: NotificationManager, notificationCenter: NotificationCenter) {
        self.session = session
        self.notificationManager = notificationManager
        self.notificationCenter = notificationCenter
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) {
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
            print("\(#file) \(#function) First registration request succeeded")

        case .failure(let error):
            // TODO How do we handle this failure?
            print("\(#file) \(#function) Error making first registration request: \(error)")
            completionHandler?(.failure(error))
        }
    }

    private func succeed(registration: Registration) {
        notificationManager.delegate = nil
        let userInfo = [RegistrationCompleteNotificationRegistrationKey : registration]
        notificationCenter.post(name: RegistrationCompleteNotification, object: nil, userInfo: userInfo)
        completionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        notificationManager.delegate = nil
        completionHandler?(.failure(error))
    }
}


extension ConcreteRegistrationService: NotificationManagerDelegate {

    func notificationManager(_ notificationManager: NotificationManager,
                             didReceiveNotificationWithInfo userInfo: [AnyHashable : Any]) {
        // I can't remember how to spell the switch to do this --RA
        if let activationCode = userInfo["activationCode"] as? String {
            didReceiveActivationCode(activationCode: activationCode)
        } else if let pushToken = userInfo["pushToken"] as? String {
            didReceivePushToken(pushToken: pushToken)
        }
    }
    
    private func didReceivePushToken(pushToken: String) {
        if registerWhenTokenReceived {
            beginRegistration()
        }
    }
    
    private func didReceiveActivationCode(activationCode: String) {
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
                 
                self.succeed(registration: registration)
                
            case .failure(let error):
                // TODO How do we handle this failure?
                print("error during registration: \(error)")
                self.fail(withError: error)
            }
        }
    }

}
