//
//  UITestScreenMaker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

#if DEBUG

import UIKit

struct UITestScreenMaker: ScreenMaking {
    
    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .onboarding:
            let onboardingViewController = OnboardingViewController.instantiate { viewController in
                let env = OnboardingEnvironment(mockWithHost: viewController)
                let bluetoothNursery = NoOpBluetoothNursery()
                let coordinator = OnboardingCoordinator(persistence: env.persistence, authorizationManager: env.authorizationManager, bluetoothNursery: bluetoothNursery)
                viewController.inject(env: env, coordinator: coordinator, bluetoothNursery: bluetoothNursery, uiQueue: DispatchQueue.main) { }
            }

            // This cludgey step is ensures that we "show" the onboarding view controller
            // which triggers the initial state to be requested from its onboarding coordinator
            // if we don't do this step then the first two onboarding screens are repeated twice
            let dummyRootViewController = DummyRootViewController()
            onboardingViewController.showIn(container: dummyRootViewController)

            return onboardingViewController
        }
    }
}

class DummyRootViewController: UIViewController, ViewControllerContainer {
    func show(viewController newChild: UIViewController) { }
}

private extension OnboardingEnvironment {
    
    convenience init(mockWithHost host: UIViewController) {
        // TODO: Fix initial state of mocks.
        // Currently it’s set so that onboarding is “done” as soon as we allow data sharing – so we can have a minimal
        // UI test.
        let authorizationManager = EphemeralAuthorizationManager()
        let notificationCenter = NotificationCenter()
        let dispatcher = RemoteNotificationDispatcher(notificationCenter: notificationCenter, userNotificationCenter: UNUserNotificationCenter.current())
        
        self.init(
            persistence: InMemoryPersistence(),
            authorizationManager: authorizationManager,
            remoteNotificationManager: EphemeralRemoteNotificationManager(host: host, authorizationManager: authorizationManager, dispatcher: dispatcher),
            notificationCenter: notificationCenter
        )
    }
    
}

private class InMemoryPersistence: Persisting {
    var delegate: PersistenceDelegate?

    var registration: Registration? = nil
    var potentiallyExposed: Bool = false
    var selfDiagnosis: SelfDiagnosis? = nil
    var partialPostcode: String? = nil
    var bluetoothPermissionRequested: Bool = false
    var uploadLog: [UploadLog] = []
    var linkingId: LinkingId?
        
    func clear() {
        registration = nil
        selfDiagnosis = nil
        partialPostcode = nil
        uploadLog = []
        linkingId = nil
    }
}

private class EphemeralAuthorizationManager: AuthorizationManaging {
    var bluetooth = BluetoothAuthorizationStatus.allowed
    var notificationsStatus = NotificationAuthorizationStatus.notDetermined
    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        completion(notificationsStatus)
    }
}

private class EphemeralRemoteNotificationManager: RemoteNotificationManager {
    
    let dispatcher: RemoteNotificationDispatching
    private let authorizationManager: EphemeralAuthorizationManager
    private weak var host: UIViewController?
    
    var pushToken: String? = nil
    
    init(host: UIViewController, authorizationManager: EphemeralAuthorizationManager, dispatcher: RemoteNotificationDispatching) {
        self.host = host
        self.authorizationManager = authorizationManager
        self.dispatcher = dispatcher
    }
    
    func configure() {
        assertionFailure("Must not be called")
    }
    
    func registerHandler(forType: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
        assertionFailure("Must not be called")
    }
    
    func removeHandler(forType type: RemoteNotificationType) {
        assertionFailure("Must not be called")
    }
    
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        let alert = UIAlertController(
            title: "“CoLocate” Would Like to Send You Notifications",
            message: "[FAKE] This alert only simulates the system alert.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Don’t Allow", style: .default, handler: { _ in
            self.authorizationManager.notificationsStatus = .denied
            completion(.failure(MockError()))
        }))
        alert.addAction(UIAlertAction(title: "Allow", style: .default, handler: { _ in
            self.authorizationManager.notificationsStatus = .allowed
            completion(.success(true))
        }))
        host?.present(alert, animated: false, completion: nil)
    }
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
        assertionFailure("Must not be called")
    }
    
}

private struct MockError: Error {}

private class NoOpBluetoothNursery: BluetoothNursery {
    var stateObserver: BluetoothStateObserver?
    var contactEventRepository: ContactEventRepository = NoOpContactEventRepository()
    var contactEventPersister: ContactEventPersister = NoOpContactEventPersister()
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
    }
    func createListener() {
    }

    func restoreListener(_ restorationIdentifiers: [String]) {
    }

    func restoreBroadcaster(_ restorationIdentifiers: [String]) {
    }
}

private class NoOpContactEventRepository: ContactEventRepository {
    var contactEvents: [ContactEvent] = []

    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
    }
        
    func reset() {
    }
    
    func removeExpiredContactEvents(ttl: Double) {
    }

    func remove(through date: Date) {
    }
    
}

private class NoOpContactEventPersister: ContactEventPersister {
    var items: [UUID : ContactEvent] = [:]
    
    func reset() {
    }
    
}

#endif
