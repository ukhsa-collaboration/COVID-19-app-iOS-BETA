//
//  RegistratonService.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging
 
protocol RegistrationService {
    func register() -> Void
}

let RegistrationCompletedNotification = Notification.Name("RegistrationCompletedNotification")
let RegistrationFailedNotification = Notification.Name("RegistrationFailedNotification")

fileprivate let registrationTimeLimitSecs = 20.0


class ConcreteRegistrationService: RegistrationService {
    private let session: Session
    private let persistence: Persisting
    private let reminderScheduler: RegistrationReminderScheduler
    private let remoteNotificationDispatcher: RemoteNotificationDispatching
    private let notificationCenter: NotificationCenter
    private let monitor: AppMonitoring
    private let timeoutQueue: TestableQueue
    private var remoteNotificationCompletionHandler: RemoteNotificationCompletionHandler?
    
    init(session: Session,
         persistence: Persisting,
         reminderScheduler: RegistrationReminderScheduler,
         remoteNotificationDispatcher: RemoteNotificationDispatching,
         notificationCenter: NotificationCenter,
         monitor: AppMonitoring,
         timeoutQueue: TestableQueue
    ) {
        self.session = session

        self.persistence = persistence
        self.reminderScheduler = reminderScheduler
        self.notificationCenter = notificationCenter
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
        self.monitor = monitor
        self.timeoutQueue = timeoutQueue
        
        // when our backend sends us the activation code in a push notification
        // we will want to make a second request to complete the registration process
        remoteNotificationDispatcher.registerHandler(forType: .registrationActivationCode) { userInfo, completion in
            guard persistence.registration == nil else {
                logger.warning("Ignoring a registration activation code notification because we are already registered.")
                return
            }
            
            self.remoteNotificationCompletionHandler = completion
            self.confirmRegistration(activationCode: userInfo["activationCode"] as! String)
        }
    }
    
    deinit {
        remoteNotificationDispatcher.removeHandler(forType: .registrationActivationCode)
        notificationCenter.removeObserver(self)
    }
    
    func register() -> Void {
        reminderScheduler.schedule()
        
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
        
        self.timeoutQueue.asyncAfter(deadline: .now() + registrationTimeLimitSecs) { [weak self] in
            guard let self = self else { return }
            guard self.persistence.registration == nil else { return }
            
            logger.error("Registration did not complete within \(registrationTimeLimitSecs) seconds")
            let hasPushToken = self.remoteNotificationDispatcher.pushToken != nil
            self.fail(
                withError: RegistrationTimeoutError(),
                reason: hasPushToken ? .waitingForActivationNotificationTimedOut : .waitingForFCMTokenTimedOut
            )
        }
    }
    
    private func requestRegistration(_ pushToken: String) {
        let request = RequestFactory.registrationRequest(pushToken: pushToken)

        session.execute(request, queue: .main) { result in
            switch result {
            case .success(_):
                logger.debug("First registration request succeeded")
                // If everything worked, we'll receive a notification with the access token
                // See confirmRegistration().

            case .failure(let error):
                logger.error("Error making first registration request: \(error.localizedDescription)")
                self.fail(withError: error, reason: .registrationCallFailed(statusCode: nil))
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
        
        session.execute(request, queue: .main) { result in
            switch result {
            case .success(let response):
                logger.debug("Second registration request succeeded")
                
                guard self.persistence.registration == nil else {
                    logger.info("Ignoring registration response because we are already registered")
                    return
                }
                
                var broadcastRotationKey: SecKey!
                
                do {
                    broadcastRotationKey = try BroadcastRotationKeyConverter().fromData(response.serverPublicKey)
                } catch {
                    logger.error("Invalid server public key in registration confirmation response: \(error.localizedDescription)")
                    return
                }
                
                let registration = Registration(
                    id: response.id,
                    secretKey: response.secretKey,
                    broadcastRotationKey: broadcastRotationKey
                )
                self.persistence.registration = registration

                self.succeed(registration: registration)
            case .failure(let error):
                logger.error("Error making second registration request: \(error)")
                self.fail(withError: error, reason: .activationCallFailed(statusCode: nil))
            }
        }
    }
    
    private func succeed(registration: Registration) {
        self.remoteNotificationCompletionHandler?(.newData)
        notificationCenter.post(name: RegistrationCompletedNotification, object: nil)
        reminderScheduler.cancel()
    }
    
    private func fail(withError error: Error, reason: AppEvent.RegistrationFailureReason) {
        logger.error("Registration failed: \(error)")
        self.remoteNotificationCompletionHandler?(.failed)
        notificationCenter.post(name: RegistrationFailedNotification, object: nil)
        monitor.report(.registrationFailed(reason: reason))
    }
}

fileprivate class RegistrationTimeoutError: Error {
    let errorDescription = "Registration did not complete within \(registrationTimeLimitSecs) seconds."
}

// MARK: - Logging
private let logger = Logger(label: "Registration")
