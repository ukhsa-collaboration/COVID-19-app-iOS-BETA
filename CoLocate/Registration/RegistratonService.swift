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

class ConcreteRegistrationService: RegistrationService {
    let session: Session
    let persistence = Persistence.shared
    var pushNotificationDispatcher: PushNotificationDispatcher
    let notificationCenter: NotificationCenter
    var registrationCompletionHandler: ((Result<Void, Error>) -> Void)?
    var pushNotificationCompletionHandler: PushNotificationCompletionHandler?
    
    init(session: Session, pushNotificationDispatcher: PushNotificationDispatcher, notificationCenter: NotificationCenter) {
        #if DEBUG
        self.session = InterceptingSession(underlyingSession: session)
        #else
        self.session = session
        #endif
        self.pushNotificationDispatcher = pushNotificationDispatcher
        self.notificationCenter = notificationCenter
    }

    convenience init() {
        self.init(
            session: URLSession.shared,
            pushNotificationDispatcher: PushNotificationDispatcher.shared,
            notificationCenter: NotificationCenter.default
        )
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) {
        self.registrationCompletionHandler = completionHandler
        
        pushNotificationDispatcher.registerHandler(forType: .registrationActivationCode) { userInfo, completion in
            self.pushNotificationCompletionHandler = completion
            self.didReceiveActivationCode(activationCode: userInfo["activationCode"] as! String)
        }

        if pushNotificationDispatcher.pushToken != nil {
            beginRegistration()
        } else {
            notificationCenter.addObserver(forName: PushTokenReceivedNotification, object: nil, queue: nil) { _ in
                self.notificationCenter.removeObserver(self, name: PushTokenReceivedNotification, object: nil)
                self.beginRegistration()
            }
        }
    }
    
    private func beginRegistration() {
        let request = RequestFactory.registrationRequest(pushToken: pushNotificationDispatcher.pushToken!)

        session.execute(request, queue: .main) { result in
            switch result {
            case .success(_):
                print("\(#file) \(#function) First registration request succeeded")
                // If everything worked, we'll receive a notification with the access token
                // See didReceiveActivationCode().

            case .failure(let error):
                print("\(#file) \(#function) Error making first registration request: \(error)")
                self.fail(withError: error)
            }
        }
    }
    
    private func didReceiveActivationCode(activationCode: String) {
        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode, pushToken: pushNotificationDispatcher.pushToken!)
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                let registration = Registration(id: response.id, secretKey: response.secretKey)

                self.persistence.registration = registration

                self.succeed(registration: registration)
            case .failure(let error):
                print("error during registration: \(error)")
                self.fail(withError: error)
            }
        }
    }
    
    private func succeed(registration: Registration) {
        cleanup()
        self.pushNotificationCompletionHandler?(.newData)
        registrationCompletionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        cleanup()
        self.pushNotificationCompletionHandler?(.failed)
        registrationCompletionHandler?(.failure(error))
    }

    private func cleanup() {
        self.pushNotificationDispatcher.removeHandler(forType: .registrationActivationCode)
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
