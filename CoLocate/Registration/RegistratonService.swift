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
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) -> Cancelable
}

protocol Cancelable {
    func cancel()
}

let RegistrationStartedNotification = NSNotification.Name("RegistrationStartedNotification")

class ConcreteRegistrationService: RegistrationService {
    let session: Session
    let persistence: Persisting
    let remoteNotificationDispatcher: RemoteNotificationDispatcher
    let notificationCenter: NotificationCenter
    
    init(session: Session,
         persistence: Persisting,
         remoteNotificationDispatcher: RemoteNotificationDispatcher,
         notificationCenter: NotificationCenter) {
        self.session = session

        self.persistence = persistence
        self.notificationCenter = notificationCenter
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
    }

    convenience init() {
        self.init(
            session: URLSession.shared,
            persistence: Persistence.shared,
            remoteNotificationDispatcher: RemoteNotificationDispatcher.shared,
            notificationCenter: NotificationCenter.default
        )
    }
    
    func register(completionHandler: @escaping ((Result<Void, Error>) -> Void)) -> Cancelable {
        let attempt = RegistrationAttempt(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            completionHandler: completionHandler
        )
        attempt.start()
        notificationCenter.post(name: RegistrationStartedNotification, object: nil)
        return attempt
    }
}

fileprivate class RegistrationAttempt: Cancelable {
    private let session: Session
    private let persistence: Persisting
    private let remoteNotificationDispatcher: RemoteNotificationDispatcher
    private let notificationCenter: NotificationCenter
    private var registrationCompletionHandler: ((Result<Void, Error>) -> Void)?
    private var remoteNotificationCompletionHandler: RemoteNotificationCompletionHandler?
    private var canceled = false

    init(
        session: Session,
        persistence: Persisting,
        remoteNotificationDispatcher: RemoteNotificationDispatcher,
        notificationCenter: NotificationCenter,
        completionHandler: @escaping ((Result<Void, Error>) -> Void)
    ) {
        self.session = session
        self.persistence = persistence
        self.notificationCenter = notificationCenter
        self.registrationCompletionHandler = completionHandler
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    func cancel() {
        canceled = true
        cleanup()
    }
    
    func start() {
        // when our backend sends us the activation code in a push notification
        // we will want to make a second request to complete the registration process
        remoteNotificationDispatcher.registerHandler(forType: .registrationActivationCode) { userInfo, completion in
            self.remoteNotificationCompletionHandler = completion
            self.confirmRegistration(activationCode: userInfo["activationCode"] as! String)
        }

        if let pushToken = remoteNotificationDispatcher.pushToken {
            // if somehow we have already received our fcm push token, perform the first registration request
            requestRegistration(pushToken)
        } else {
            // otherwise when it later appears, we can perform the first of two registration requests
            notificationCenter.addObserver(forName: PushTokenReceivedNotification, object: nil, queue: nil) { notification in
                guard let pushToken = notification.object as? String else { return }

                self.notificationCenter.removeObserver(self, name: PushTokenReceivedNotification, object: nil)
                self.requestRegistration(pushToken)
            }
        }
    }
    
    private func requestRegistration(_ pushToken: String) {
        if canceled {
            return
        }
        
        let request = RequestFactory.registrationRequest(pushToken: pushToken)

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
        guard let pushToken = remoteNotificationDispatcher.pushToken else {
            logger.critical("Tried to register without push token.")
            return
        }
        guard let partialPostalCode = persistence.partialPostcode else {
            logger.critical("Tried to register without partial postalCode")
            return
        }

        let request = RequestFactory.confirmRegistrationRequest(activationCode: activationCode,
                                                                pushToken: pushToken,
                                                                postalCode: partialPostalCode)
        
        session.execute(request, queue: .main) { [weak self] result in
            guard let self = self, !self.canceled else { return }

            switch result {
            case .success(let response):
                logger.debug("Second registration request succeeded")

                let registration = Registration(id: response.id, secretKey: response.secretKey)
                self.persistence.registration = registration

                self.succeed(registration: registration)
            case .failure(let error):
                logger.error("Error making second registration request: \(error)")
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

// MARK: - Logging
private let logger = Logger(label: "RegistrationService")
