//
//  UITestScreenMaker.swift
//  Sonar
//
//  Created by NHSX on 06/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

#if DEBUG

import UIKit
import CoreBluetooth

struct UITestScreenMaker: ScreenMaking {
    
    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .onboarding:
            let onboardingViewController = OnboardingViewController.instantiate { viewController in
                let env = OnboardingEnvironment(mockWithHost: viewController)
                let bluetoothNursery = NoOpBluetoothNursery()
                let coordinator = OnboardingCoordinator(persistence: env.persistence,
                    authorizationManager: env.authorizationManager,
                    bluetoothNursery: bluetoothNursery
                )
                viewController.inject(env: env, coordinator: coordinator, bluetoothNursery: bluetoothNursery, uiQueue: DispatchQueue.main) { }
            }

            return onboardingViewController

        case .status:
            let statusViewController = StatusViewController.instantiate { viewController in
                let persistence = InMemoryPersistence();
                viewController.inject(persistence: persistence,
                    registrationService: MockRegistrationService(),
                    contactEventsUploader: MockContactEventsUploading(),
                    notificationCenter: NotificationCenter(),
                    linkingIdManager: MockLinkingIdManager(),
                    statusProvider: StatusProvider(persisting: persistence),
                    localeProvider: FixedLocaleProvider()
                )
            }

            return statusViewController
        }
    }
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
    var potentiallyExposed: Date?
    var selfDiagnosis: SelfDiagnosis? = nil
    var partialPostcode: String? = nil
    var bluetoothPermissionRequested: Bool = false
    var uploadLog: [UploadLog] = []
    var lastInstalledVersion: String?
    var lastInstalledBuildNumber: String?
    var acknowledgmentUrls: Set<URL> = []
    var statusState: StatusState = .ok(StatusState.Ok())

    func clear() {
        registration = nil
        potentiallyExposed = nil
        selfDiagnosis = nil
        partialPostcode = nil
        uploadLog = []
        lastInstalledVersion = nil
        lastInstalledBuildNumber = nil
        acknowledgmentUrls = []
        statusState = .ok(StatusState.Ok())
    }
}

private class MockRegistrationService: RegistrationService {
    var registerCalled = false

    func register() {
        registerCalled = true
    }
}

private class MockContactEventsUploading: ContactEventsUploading {
    var sessionDelegate: ContactEventsUploaderSessionDelegate = ContactEventsUploaderSessionDelegate(validator: MockTrustValidating())

    func upload(from startDate: Date) throws {}
    func cleanup() {}
    func error(_ error: Swift.Error) {}
    func ensureUploading() throws {}
}

private class MockTrustValidating: TrustValidating {
    func canAccept(_ trust: SecTrust?) -> Bool {
        return true
    }
}

private class FixedLocaleProvider: LocaleProvider {
    var locale: Locale = Locale(identifier: "en")
}

private class MockLinkingIdManager: LinkingIdManaging {
    func fetchLinkingId(completion: @escaping (LinkingId?) -> Void) {
    }
}

private class EphemeralAuthorizationManager: AuthorizationManaging {

    var notificationsStatus = NotificationAuthorizationStatus.notDetermined
    var bluetooth: BluetoothAuthorizationStatus = .allowed

    func waitForDeterminedBluetoothAuthorizationStatus(completion: @escaping (BluetoothAuthorizationStatus) -> Void) {
        completion(BluetoothAuthorizationStatus.allowed)
    }
    
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
            title: "“Sonar” Would Like to Send You Notifications",
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
    var hasStarted = false
    func startBluetooth(registration: Registration?) {
        hasStarted = true
    }

    var stateObserver: BluetoothStateObserving = BluetoothStateObserver(initialState: .poweredOn)
    var contactEventRepository: ContactEventRepository = NoOpContactEventRepository()
    var contactEventPersister: ContactEventPersister = NoOpContactEventPersister()
    var broadcaster: BTLEBroadcaster? = NoOpBroadcaster()
}

private class NoOpContactEventRepository: ContactEventRepository {
    var contactEvents: [ContactEvent] = []
    
    var delegate: ContactEventRepositoryDelegate?

    func btleListener(_ listener: BTLEListener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, for peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadTxPower txPower: Int, for peripheral: BTLEPeripheral) {
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
    
    func update(item: ContactEvent, key: UUID) {
    }
    
    func remove(key: UUID) {
    }
    
    func replaceAll(with: [UUID : ContactEvent]) {
    }

    func reset() {
    }
    
}

private class NoOpBroadcaster: BTLEBroadcaster {
    func updateIdentity() {
    }
    
    func sendKeepalive(value: Data) {
    }

    func isHealthy() -> Bool {
        return false
    }
}

#endif
