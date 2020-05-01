//
//  RegistrationServiceTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class RegistrationServiceTests: TestCase {

    let id = UUID()
    let secretKey = "a secret key".data(using: .utf8)!

    func testRegistration_withPreExistingPushToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
            timeoutQueue: QueueDouble()
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
        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(
            id: id,
            secretKey: secretKey,
            serverPublicKey: knownGoodRotationKeyData()
        )
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertNotNil(completedObserver.lastNotification)

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration?.id)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
            timeoutQueue: QueueDouble()
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
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))

        XCTAssertNotNil(completedObserver.lastNotification)

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration?.id)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)
        let expectedRotationKey = try BroadcastRotationKeyConverter().fromData(knownGoodRotationKeyData())
        XCTAssertEqual(expectedRotationKey, storedRegistration?.broadcastRotationKey)

        // Make sure we cleaned up after ourselves
        XCTAssertTrue(remoteNotificatonCallbackCalled)
    }
    
    func testRegistration_notifiesOnInitialRequestFailure() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: QueueDouble()
        )
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        _ = registrationService.register()
        
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.failure(ErrorForTest()))

        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .registrationCallFailed)])
    }
    
    func testRegistration_notifiesOnSecondRequestFailure() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: QueueDouble()
        )
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)

        _ = registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in }

        // Respond to the second request
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.failure(ErrorForTest()))

        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .activationCallFailed)])
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
            timeoutQueue: QueueDouble()
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
    
    func testRegistration_timesOutAfter20Seconds_withoutPushToken() {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: queueDouble
        )

        _ = registrationService.register()

        queueDouble.scheduledBlock?()
        
        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .waitingForFCMTokenTimedOut)])
    }
    
    func testRegistration_timesOutAfter20Seconds_withoutActivationPush() {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let queueDouble = QueueDouble()
        let failedObserver = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationFailedNotification)
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: monitor,
            timeoutQueue: queueDouble
        )

        _ = registrationService.register()

        queueDouble.scheduledBlock?()
        
        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertEqual(monitor.detectedEvents, [.registrationFailed(reason: .waitingForActivationNotificationTimedOut)])
    }
    
    func testRegistration_canSucceedAfterTimeout() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
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
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
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
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
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
        let confirmationResponse1 = ConfirmRegistrationResponse(id: id1, secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse1))
        XCTAssertNotNil(completedObserver.lastNotification)
        completedObserver.lastNotification = nil
        failedObserver.lastNotification = nil
        let id2 = UUID()
        let confirmationResponse2 = ConfirmRegistrationResponse(id: id2, secretKey: secretKey, serverPublicKey: Data())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse2))
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNil(failedObserver.lastNotification)
        XCTAssertNotNil(persistence.registration)
        XCTAssertEqual(persistence.registration?.id, id1)
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
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
        let confirmationResponse = ConfirmRegistrationResponse(id: UUID(), secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        XCTAssertNotNil(completedObserver.lastNotification)
        
        completedObserver.lastNotification = nil
        session.requestSent = nil
        
        // Simulate a second notificaiton.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "anything"]) { _ in }
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNil(session.requestSent)
    }
    
    
    func testRegistration_canFailAfterTimeout() {
        let session = SessionDouble()
        let persistence = PersistenceDouble(partialPostcode: "AB90")
        let notificationCenter = NotificationCenter()
        let monitor = AppMonitoringDouble()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble()
        )
        let queueDouble = QueueDouble()
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: RegistrationReminderSchedulerDouble(),
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
                
        queueDouble.scheduledBlock?()
        failedObserver.lastNotification = nil
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        // Respond to the second request
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.failure(ErrorForTest()))
        
        XCTAssertNil(completedObserver.lastNotification)
        XCTAssertNotNil(failedObserver.lastNotification)
        XCTAssertNil(persistence.registration)
        
        #warning("This is probably not what we want.")
        // I don’t believe the issue is just for the metrics, since we’re “failing” multiple times.
        // Review please…
        XCTAssertEqual(monitor.detectedEvents, [
            .registrationFailed(reason: .waitingForActivationNotificationTimedOut),
            .registrationFailed(reason: .activationCallFailed)
        ])
    }
    
    func testSchedulesRemindersAtStart() {
        let reminderScheduler = RegistrationReminderSchedulerDouble()
        
        let registrationService = ConcreteRegistrationService(
            session: SessionDouble(),
            persistence: PersistenceDouble(),
            reminderScheduler: reminderScheduler,
            remoteNotificationDispatcher: RemoteNotificationDispatcher(
                notificationCenter: NotificationCenter(),
                userNotificationCenter: UserNotificationCenterDouble()
            ),
            notificationCenter: NotificationCenter(), monitor: AppMonitoringDouble(),
            timeoutQueue: QueueDouble()
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
        let registrationService = ConcreteRegistrationService(
            session: session,
            persistence: persistence,
            reminderScheduler: reminderScheduler,
            remoteNotificationDispatcher: remoteNotificationDispatcher,
            notificationCenter: notificationCenter,
            monitor: AppMonitoringDouble(),
            timeoutQueue: QueueDouble()
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        
        registrationService.register()
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
                
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
                        
        let confirmationResponse = ConfirmRegistrationResponse(id: UUID(), secretKey: secretKey, serverPublicKey: knownGoodRotationKeyData())
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(reminderScheduler.cancelCalled)
    }
    
    private func knownGoodRotationKeyData() -> Data {
        let data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return data
    }
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
