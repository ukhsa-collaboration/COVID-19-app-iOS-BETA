//
//  RegistrationServiceTests.swift
//  SonarTests
//
//  Created by NHSX on 3/26/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class RegistrationServiceTests: TestCase {

    let sonarId = UUID()
    let secretKey = SecKey.sampleHMACKey

    func testRegistration_withPreExistingPushToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)
        _ = registrationService.register()
        
        // Verify the first request
        let registrationRequestData = (session.requestSent as! RegistrationRequest).body!
        let registrationResponse = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: registrationRequestData)
        XCTAssertEqual(registrationResponse.pushToken, "the current push token")
        
        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        
        var remoteNotificatonCallbackCalled = false
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in
            remoteNotificatonCallbackCalled = true
        }
        
        // Verify the second request
        let confirmRegistrationRequest = (session.requestSent as! ConfirmRegistrationRequest).body!
        let confirmRegistrationPayload = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: confirmRegistrationRequest)
        XCTAssertEqual(confirmRegistrationPayload.activationCode, UUID(uuidString: activationCode))
        XCTAssertEqual(confirmRegistrationPayload.pushToken, "the current push token")
        XCTAssertEqual(confirmRegistrationPayload.postalCode, "AB90")
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNil(persistence.registeredPushToken) // Should not persist this until registration completes
        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(
            sonarId: sonarId,
            secretKey: secretKey,
            serverPublicKey: knownGoodRotationKeyData()
        )
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertNotNil(completedObserver.lastNotification)

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(sonarId, storedRegistration?.sonarId)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)
        XCTAssertEqual("the current push token", persistence.registeredPushToken)
        let expectedRotationKey = try BroadcastRotationKeyConverter().fromData(knownGoodRotationKeyData())
        XCTAssertEqual(expectedRotationKey, storedRegistration?.broadcastRotationKey)

        // Make sure we cleaned up after ourselves
        XCTAssertTrue(remoteNotificatonCallbackCalled)
    }
    
    func testRegistration_withoutPreExistingPushToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )

        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)

        _ = registrationService.register()
        
        XCTAssertNil(session.requestSent)

        // Simulate receiving the push token
        remoteNotificationDispatcher.receiveRegistrationToken(fcmToken: "a push token")
        // Verify the first request
        let registrationBody = (session.requestSent as! RegistrationRequest).body!
        let registrationPayload = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: registrationBody)
        XCTAssertEqual(registrationPayload.pushToken, "a push token")

        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        var remoteNotificatonCallbackCalled = false
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in
            remoteNotificatonCallbackCalled = true
        }

        // Verify the second request
        let confirmRegistrationBody = (session.requestSent as! ConfirmRegistrationRequest).body!
        let confirmRegistrationPayload = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: confirmRegistrationBody)
        XCTAssertEqual(confirmRegistrationPayload.activationCode, UUID(uuidString: activationCode))
        XCTAssertEqual(confirmRegistrationPayload.pushToken, "a push token")
        XCTAssertEqual(confirmRegistrationPayload.postalCode, "AB90")

        XCTAssertNil(completedObserver.lastNotification)

        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(sonarId: sonarId, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))

        XCTAssertNotNil(completedObserver.lastNotification)

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(sonarId, storedRegistration?.sonarId)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)
        XCTAssertEqual("a push token", persistence.registeredPushToken)
        let expectedRotationKey = try BroadcastRotationKeyConverter().fromData(knownGoodRotationKeyData())
        XCTAssertEqual(expectedRotationKey, storedRegistration?.broadcastRotationKey)

        // Make sure we cleaned up after ourselves
        XCTAssertTrue(remoteNotificatonCallbackCalled)
    }
    
    func testRegistration_immediatelyPersistsPushTokenIfAlreadyRegisteredAndPreexistingToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
    
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
        
        XCTAssertEqual(persistence.registeredPushToken, "the current push token")
    }
    
    func testRegistration_immediatelyPersistsPushTokenIfAlreadyRegisteredAndNewToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
    
        remoteNotificationDispatcher.receiveRegistrationToken(fcmToken: "the current push token")
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
        
        XCTAssertEqual(persistence.registeredPushToken, "the current push token")
    }
    
    func testRegistration_doesNotOverridePersistedPushTokenIfAlreadyRegisteredAndPreexistingToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        
        persistence.registeredPushToken = "old token"
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
    
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
        
        XCTAssertEqual(persistence.registeredPushToken, "old token")
    }
    
    func testRegistration_doesNotOverridePersistedPushTokenIfAlreadyRegisteredAndNewToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        persistence.registeredPushToken = "old token"
        
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
    
        remoteNotificationDispatcher.receiveRegistrationToken(fcmToken: "the current push token")
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
        
        XCTAssertEqual(persistence.registeredPushToken, "old token")
    }
    
    func testRegistration_sendsTheNewPushTokenWhenItChangesAndSavesItOnSuccess() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        
        persistence.registeredPushToken = "old token"
        
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
        
        remoteNotificationDispatcher.receiveRegistrationToken(fcmToken: "new token")
        
        let request = try XCTUnwrap(session.requestSent as? UpdatePushNotificationTokenRequest)
        let requestBody = try XCTUnwrap(request.method.body)
        let putToken = try JSONDecoder().decode([String: String].self, from: requestBody)["pushNotificationToken"]
        XCTAssertEqual(putToken, "new token")

        // Do not save the token until we succeed
        XCTAssertEqual(persistence.registeredPushToken, "old token")
        
        session.executeCompletion?(Result<(), Error>.success(()))
        XCTAssertEqual(persistence.registeredPushToken, "new token")
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
    }
    
    func testRegistration_doesNotReSendPushTokenIfItHasNotChanged() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        persistence.registration = .fake
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        
        persistence.registeredPushToken = "the current push token"
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
        
        XCTAssertNil(session.requestSent)
                
        XCTAssertEqual(persistence.registeredPushToken, "the current push token")
        
        withExtendedLifetime(registrationService) {
            XCTAssertNotNil(registrationService)
        }
        
    }
    
    func testRegistration_notifiesOnInitialRequestFailureAfterHourDelay() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let timeoutQueue = QueueDouble()
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: timeoutQueue
        )
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        _ = registrationService.register()
        
        session.requestSent = nil
        let expectedDeadline = DispatchTime.now() + secondsDelayAfterFailure
        session.executeCompletion!(Result<(), Error>.failure(ErrorForTest()))

        // The failure should be recorded immediately but not reported to the rest of the application
        // until the delay elapses.
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .registrationCallFailed(statusCode: nil))])
        XCTAssertNil(failedObserver.lastNotification)

        XCTAssertGreaterThanOrEqual(try XCTUnwrap(timeoutQueue.deadline), expectedDeadline)
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()
        
        XCTAssertNotNil(failedObserver.lastNotification)
    }
    
    func testRegistration_notifiesOnSecondRequestFailureAfterHourDelay() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let timeoutQueue = QueueDouble()
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: timeoutQueue
        )
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        _ = registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in }

        let expectedDeadline = DispatchTime.now() + secondsDelayAfterFailure
        // Respond to the second request
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.failure(ErrorForTest()))

        // The failure should be recorded immediately but not reported to the rest of the application
        // until the delay elapses.
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .activationCallFailed(statusCode: nil))])
        XCTAssertNil(failedObserver.lastNotification)


        XCTAssertGreaterThanOrEqual(try XCTUnwrap(timeoutQueue.deadline), expectedDeadline)
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()
        
        XCTAssertNotNil(failedObserver.lastNotification)
    }
    
    func testRegistration_cleansUpAfterInitialRequestFailure() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )

        _ = registrationService.register()
        
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.failure(ErrorForTest()))

        // We should not have unsusbscribed from push notifications.
        XCTAssertTrue(remoteNotificationDispatcher.hasHandler(forType: .registrationActivationCode))
        
        // We should also have unsubscribe from the PushTokenReceivedNotification. We can't test that directly but we can observe its effects.
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)
        XCTAssertNil(session.requestSent)
    }
    
    func testRegistration_timesOutAfterOneHour_withoutPushToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let timeoutQueue = QueueDouble()
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: timeoutQueue
        )

        let expectedDeadline = DispatchTime.now() + secondsDelayAfterFailure
        _ = registrationService.register()

        XCTAssertGreaterThanOrEqual(try XCTUnwrap(timeoutQueue.deadline), expectedDeadline)
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()
        
        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .waitingForFCMTokenTimedOut)])
    }
    
    func testRegistration_timesOutAfterOneHour_withoutActivationPush() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let timeoutQueue = QueueDouble()
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: timeoutQueue
        )

        let expectedDeadline = DispatchTime.now() + secondsDelayAfterFailure
        _ = registrationService.register()

        XCTAssertGreaterThanOrEqual(try XCTUnwrap(timeoutQueue.deadline), expectedDeadline)
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()

        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .waitingForActivationNotificationTimedOut)])
    }
    
    // MARK: - Preventing concurrent registration attempts
    
    func testRegistration_isNoOpIfAlreadyRegistering() {
        let session = SessionDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatchingDouble()
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = makeRegistrationService(
            session: session,
            persistence: PersistenceDouble(partialPostcode: "AB90"),
            remoteNotificationDispatcher: remoteNotificationDispatcher
        )
        
        registrationService.register()
        
        session.requestSent = nil
        registrationService.register()
        XCTAssertNil(session.requestSent)
    }
    
    func testRegistration_allowsRegistrationAfterDelayWhenFirstRequestFails() throws {
        let session = SessionDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatchingDouble()
        let timeoutQueue = QueueDouble()
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = makeRegistrationService(
            session: session,
            persistence: PersistenceDouble(partialPostcode: "AB90"),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            timeoutQueue: timeoutQueue
        )
        
        registrationService.register()
        
        // Respond to the first request
        let firstRequestCompletion = try XCTUnwrap(session.executeCompletion)
        firstRequestCompletion(Result<(), Error>.failure(ErrorForTest()))
        
        // Nothing should happen if we try to re-register right away
        session.requestSent = nil
        registrationService.register()
        XCTAssertNil(session.requestSent as? RegistrationRequest)

        // But doing it after the delay should work
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()
        session.requestSent = nil
        registrationService.register()
        XCTAssertNotNil(session.requestSent as? RegistrationRequest)
    }
    
    func testRegistration_allowsRegistrationAfterDelayWhenSecondRequestFails() throws {
        let session = SessionDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let timeoutQueue = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: PersistenceDouble(partialPostcode: "AB90"),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            timeoutQueue: timeoutQueue
        )
        
        registrationService.register()
        
        // Respond to the first request
        let firstRequestCompletion = try XCTUnwrap(session.executeCompletion)
        session.executeCompletion = nil
        firstRequestCompletion(Result<(), Error>.success(()))
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in }
        
        // Respond to the second request
        let secondRequestCompletion = try XCTUnwrap(session.executeCompletion)
        secondRequestCompletion(Result<ConfirmRegistrationResponse, Error>.failure(ErrorForTest()))

        // Nothing should happen if we try to re-register right away
        session.requestSent = nil
        registrationService.register()
        XCTAssertNil(session.requestSent as? RegistrationRequest)

        // But doing it after the delay should work
        (try XCTUnwrap(timeoutQueue.scheduledBlock))()
        session.requestSent = nil
        registrationService.register()
        XCTAssertNotNil(session.requestSent as? RegistrationRequest)
    }
    
    func testRegistration_allowsRegistrationAfterTimeout() throws {
        let session = SessionDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatchingDouble()
        remoteNotificationDispatcher.pushToken = "the current push token"
        let timeoutQueue = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: PersistenceDouble(partialPostcode: "AB90"),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            timeoutQueue: timeoutQueue
        )
        
        registrationService.register()
        let timeoutCallback = try XCTUnwrap(timeoutQueue.scheduledBlock)
        timeoutCallback()
        
        session.requestSent = nil
        registrationService.register()
        XCTAssertNotNil(session.requestSent as? RegistrationRequest)
    }

    
    // MARK: - Late-arriving notifications
    
    func testRegistration_canSucceedAfterTimeout() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            timeoutQueue: queueDouble
        )
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))

        // More than 20 seconds has elapsed, and we show a failure
        queueDouble.scheduledBlock?()
        failedObserver.lastNotification = nil
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(sonarId: sonarId, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertNotNil(completedObserver.lastNotification)
        XCTAssertNil(failedObserver.lastNotification)
        XCTAssertNotNil(persistence.registration)
        
        // We should also have unsubscribed from the PushTokenReceivedNotification. We can't test that directly but we can observe its effects.
        session.requestSent = nil
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)
        XCTAssertNil(session.requestSent)
    }

    func testRegistration_does_not_timeout_after_success() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            timeoutQueue: queueDouble
        )

        remoteNotificationDispatcher.pushToken = "the current push token"
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        registrationService.register()

        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }

        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(sonarId: sonarId, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))

        // More than 20 seconds has elapsed, and we show a failure
        queueDouble.scheduledBlock?()

        XCTAssertNotNil(completedObserver.lastNotification)
        XCTAssertNil(failedObserver.lastNotification)
        XCTAssertNotNil(persistence.registration)
    }
    
    func testRegistration_ignoresSecondSuccess() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            timeoutQueue: queueDouble
        )
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
                
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        // Respond to the second request twice
        // This can happen if registration timed out and the user retried, but both attempts eventually succeeded.
        let id1 = UUID()
        let confirmationResponse1 = ConfirmRegistrationResponse(sonarId: id1, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse1))
        XCTAssertNotNil(completedObserver.lastNotification)
        completedObserver.lastNotification = nil
        failedObserver.lastNotification = nil
        let id2 = UUID()
        let confirmationResponse2 = ConfirmRegistrationResponse(sonarId: id2, secretKey: secretKey, serverPublicKey: Data())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse2))
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNil(failedObserver.lastNotification)
        XCTAssertNotNil(persistence.registration)
        XCTAssertEqual(persistence.registration?.sonarId, id1)
    }

    func testRegistration_ignoresSecondAccessTokenAfterSuccess() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            timeoutQueue: queueDouble
        )
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)

        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
                
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(sonarId: UUID(), secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        XCTAssertNotNil(completedObserver.lastNotification)
        
        completedObserver.lastNotification = nil
        session.requestSent = nil
        
        // Simulate a second notificaiton.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "anything"]) { _ in }
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNil(session.requestSent)
    }
    
    
    func testRegistration_canFailAfterTimeout() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: queueDouble
        )
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        let completedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompletedNotification)
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
                
        (try XCTUnwrap(queueDouble.scheduledBlock))()
        queueDouble.scheduledBlock = nil
        failedObserver.lastNotification = nil
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        // Respond to the second request
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.failure(ErrorForTest()))
        (try XCTUnwrap(queueDouble.scheduledBlock))()
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertNil(persistence.registration)
        
        #warning("This is probably not what we want.")
        // I don’t believe the issue is just for the metrics, since we’re “failing” multiple times.
        // Review please…
        XCTAssertEqual(monitor.detectedEvents, [
            .registrationFailed(reason: .waitingForActivationNotificationTimedOut),
            .registrationFailed(reason: .activationCallFailed(statusCode: nil))
        ])
    }
    
    func testSchedulesRemindersAtStart() {
        let reminderScheduler = RegistrationReminderSchedulerDouble()
        
        let registrationService = makeRegistrationService(
            reminderScheduler: reminderScheduler,
            remoteNotificationDispatcher: RemoteNotificationDispatcher(
                notificationCenter: NotificationCenter(),
                userNotificationCenter: UserNotificationCenterDouble()
            )
        )
        
        registrationService.register()
        
        XCTAssertTrue(reminderScheduler.scheduleCalled)
    }
        
    func testCancelsReminderOnSuccess() {
        let reminderScheduler = RegistrationReminderSchedulerDouble()
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let registrationService = makeRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: reminderScheduler,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
                
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        let confirmationResponse = ConfirmRegistrationResponse(sonarId: UUID(), secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(reminderScheduler.cancelCalled)
    }
    
    private func knownGoodRotationKeyData() -> Data {
        let data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return data
    }
}

private func makeRegistrationService(
    session: Session = SessionDouble(),
    persistence: Persisting = PersistenceDouble(),
    reminderScheduler: RegistrationReminderScheduler = RegistrationReminderSchedulerDouble(),
    remoteNotificationDispatcher: RemoteNotificationDispatching,
    notificationCenter: NotificationCenter = NotificationCenter(),
    monitor: AppMonitoring = AppMonitoringDouble(),
    timeoutQueue: TestableQueue = QueueDouble()
) -> ConcreteRegistrationService {
    return ConcreteRegistrationService(
        session: session,
        persistence: persistence,
        reminderScheduler: reminderScheduler,
        remoteNotificationDispatcher: remoteNotificationDispatcher,
        notificationCenter: notificationCenter,
        monitor: monitor,
        timeoutQueue: timeoutQueue
    )
}

private struct ExpectedRegistrationRequestBody: Codable {
    let pushToken: String
}

private struct ExpectedConfirmRegistrationRequestBody: Codable {
    let activationCode: UUID
    let pushToken: String
    let postalCode: String
}

private class RegistrationReminderSchedulerDouble: RegistrationReminderScheduler {
    var scheduleCalled = false
    var cancelCalled = false
    
    func schedule() {
        scheduleCalled = true
    }
    
    func cancel() {
        cancelCalled = true
    }
}

private let secondsDelayAfterFailure: Double = 60 * 60
