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

    convenience init() {
        self.init(
            session: URLSession.shared,
            pushNotificationManager: ConcretePushNotificationManager.shared,
            notificationCenter: NotificationCenter.default
        )
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) {
        self.completionHandler = completionHandler
        
        pushNotificationManager.registerHandler(forType: .registrationActivationCode) { userInfo, completionHandler in
            self.didReceiveActivationCode(activationCode: userInfo["activationCode"] as! String)
            self.pushNotificationManager.removeHandler(forType: .registrationActivationCode)
        }

        if pushNotificationManager.pushToken != nil {
            beginRegistration()
        } else {
            notificationCenter.addObserver(forName: PushTokenReceivedNotification, object: nil, queue: nil) { _ in
                self.notificationCenter.removeObserver(self, name: PushTokenReceivedNotification, object: nil)
                self.beginRegistration()
            }
        }
    }
    
    private func beginRegistration() {
        let request = RequestFactory.registrationRequest(pushToken: pushNotificationManager.pushToken!)

        session.execute(request, queue: .main) { result in
            switch result {
            case .success(_):
                print("\(#file) \(#function) First registration request succeeded")
                // If everything worked, we'll receive a notification with the access token
                // See didReceiveActivationCode().

            case .failure(let error):
                print("\(#file) \(#function) Error making first registration request: \(error)")
                self.completionHandler?(.failure(error))
            }
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
                print("error during registration: \(error)")
                self.fail(withError: error)
            }
        }
    }

    
    private func succeed(registration: Registration) {
        let userInfo = [RegistrationCompleteNotificationRegistrationKey : registration]
        notificationCenter.post(name: RegistrationCompleteNotification, object: nil, userInfo: userInfo)
        completionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        completionHandler?(.failure(error))
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
