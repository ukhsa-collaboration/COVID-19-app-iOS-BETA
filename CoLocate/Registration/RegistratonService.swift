//
//  RegistratonService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol RegistrationService {
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void))
}

class ConcreteRegistrationService: RegistrationService {
    let session: Session
    let remoteNotificationDispatcher: RemoteNotificationDispatcher
    let notificationCenter: NotificationCenter
    
    init(session: Session, remoteNotificationDispatcher: RemoteNotificationDispatcher, notificationCenter: NotificationCenter) {
        #if DEBUG
        self.session = InterceptingSession(underlyingSession: session)
        #else
        self.session = session
        #endif
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
        self.notificationCenter = notificationCenter
    }

    convenience init() {
        self.init(
            session: URLSession.shared,
            remoteNotificationDispatcher: RemoteNotificationDispatcher.shared,
            notificationCenter: NotificationCenter.default
        )
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) {
        let attempt = RegistrationAttempt(
            session: session,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            completionHandler: completionHandler
        )
        attempt.start()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
}

class RegistrationAttempt {
    let session: Session
    let persistence = Persistence.shared
    let remoteNotificationDispatcher: RemoteNotificationDispatcher
    let notificationCenter: NotificationCenter
    var registrationCompletionHandler: ((Result<Void, Error>) -> Void)?
    var remoteNotificationCompletionHandler: RemoteNotificationCompletionHandler?

    init(
        session: Session,
        remoteNotificationDispatcher: RemoteNotificationDispatcher,
        notificationCenter: NotificationCenter,
        completionHandler: @escaping ((Result<Void, Error>) -> Void)
    ) {
        self.session = session
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
        self.notificationCenter = notificationCenter
        self.registrationCompletionHandler = completionHandler
    }
    
    func start() {
        remoteNotificationDispatcher.registerHandler(forType: .registrationActivationCode) { userInfo, completion in
            self.remoteNotificationCompletionHandler = completion
            self.confirmRegistration(activationCode: userInfo["activationCode"] as! String)
        }

        if remoteNotificationDispatcher.pushToken != nil {
            requestRegistration()
        } else {
            notificationCenter.addObserver(forName: PushTokenReceivedNotification, object: nil, queue: nil) { _ in
                self.notificationCenter.removeObserver(self, name: PushTokenReceivedNotification, object: nil)
                self.requestRegistration()
            }
        }
    }
    
    private func requestRegistration() {
        let request = RequestFactory.registrationRequest(pushToken: remoteNotificationDispatcher.pushToken!)

        session.execute(request, queue: .main) { result in
            switch result {
            case .success(_):
                logger.debug("First registration request succeeded")
                // If everything worked, we'll receive a notification with the access token
                // See confirmRegistration().

            case .failure(let error):
                logger.error("Error making first registration request: \(error)")
                self.fail(withError: error)
            }
        }
    }
    
    private func confirmRegistration(activationCode: String) {
        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode, pushToken: remoteNotificationDispatcher.pushToken!)
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                let registration = Registration(id: response.id, secretKey: response.secretKey)

                self.persistence.registration = registration

                self.succeed(registration: registration)
            case .failure(let error):
                logger.error("error during registration: \(error)")
                self.fail(withError: error)
            }
        }
    }
    
    private func succeed(registration: Registration) {
        cleanup()
        self.remoteNotificationCompletionHandler?(.newData)
        registrationCompletionHandler?(.success(()))
    }
    
    private func fail(withError error: Error) {
        cleanup()
        self.remoteNotificationCompletionHandler?(.failed)
        registrationCompletionHandler?(.failure(error))
    }

    private func cleanup() {
        self.remoteNotificationDispatcher.removeHandler(forType: .registrationActivationCode)
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
        logger.debug("Intercepted an HTTP request. This request will not be sent:\n\(request)")

        if case .post(let data) = request.method {
            if let s = String(data: data, encoding: .utf8) {
                logger.debug("Request body as string: \(s)")
            }
        }
    }
}
#endif

private let logger = Logger(label: "RegistrationService")
