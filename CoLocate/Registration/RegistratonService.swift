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
    var pushNotificationManager: PushNotificationManager
    let notificationCenter: NotificationCenter
    var registerWhenTokenReceived = false
    var completionHandler: ((Result<Void, Error>) -> Void)?
    
    init(session: Session, pushNotificationManager: PushNotificationManager, notificationCenter: NotificationCenter) {
        #if DEBUG
        self.session = InterceptingSession(underlyingSession: session)
        #else
        self.session = session
        #endif
        self.pushNotificationManager = pushNotificationManager
        self.notificationCenter = notificationCenter
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) {
        self.completionHandler = completionHandler
        pushNotificationManager.delegate = self

        if pushNotificationManager.pushToken == nil {
            registerWhenTokenReceived = true
            return
        } else {
            beginRegistration()
        }
    }
    
    private func beginRegistration() {
        let request = RequestFactory.registrationRequest(pushToken: pushNotificationManager.pushToken!)

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
        pushNotificationManager.delegate = nil
        let userInfo = [RegistrationCompleteNotificationRegistrationKey : registration]
        notificationCenter.post(name: RegistrationCompleteNotification, object: nil, userInfo: userInfo)
        completionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        pushNotificationManager.delegate = nil
        completionHandler?(.failure(error))
    }
}


extension ConcreteRegistrationService: PushNotificationManagerDelegate {

    func pushNotificationManager(_ pushNotificationManager: PushNotificationManager,
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
        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode, pushToken: pushNotificationManager.pushToken!)
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


#if DEBUG
class InterceptingSession: Session {
    static var interceptNextRequest: Bool  = false
    
    var delegateQueue: OperationQueue {
        get {
            return underlyingSession.delegateQueue
        }
    }
    
    private let underlyingSession: Session
    
    init(underlyingSession: Session) {
        self.underlyingSession = underlyingSession
    }
    
    func execute<R>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) where R : Request {
        
        if InterceptingSession.interceptNextRequest {
            interceptRequest(request)
        } else {
            underlyingSession.execute(request, queue: queue, completion: completion)
        }
    }
    
    func execute<R>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) where R : Request {
        
        if InterceptingSession.interceptNextRequest {
            interceptRequest(request)
        } else {
            underlyingSession.execute(request, completion: completion)
        }
    }
    
    private func interceptRequest<R: Request>(_ request: R) {
        InterceptingSession.interceptNextRequest = false
        print("Intercepted an HTTP request. This request will not be sent:\n\(request)")
        if case .post(let data) = request.method {
            if let s = String(data: data, encoding: .utf8) {
                print("Request body as string: \(s)")
            }
        }
    }
}
#endif
