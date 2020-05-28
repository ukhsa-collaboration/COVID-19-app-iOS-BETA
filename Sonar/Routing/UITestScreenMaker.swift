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

class UITestScreenMaker {
    private let persistence = InMemoryPersistence()
    private let bluetoothNursery = NoOpBluetoothNursery()
    private let userStatusProvider = UserStatusProvider(localeProvider: FixedLocaleProvider())
    private let authorizationManager = EphemeralAuthorizationManager()
    private let notificationCenter = NotificationCenter.default
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let contactEventsUploader = MockContactEventsUploading()
    private let linkingIdManager = MockLinkingIdManager()
    private let registrationService = MockRegistrationService()

    private var mockedDate = Date()
    private lazy var dateProvider = { self.mockedDate }

    private lazy var dispatcher = RemoteNotificationDispatcher(
        notificationCenter: notificationCenter,
        userNotificationCenter: userNotificationCenter
    )
    private lazy var onboardingCoordinator = OnboardingCoordinator(
        persistence: persistence,
        authorizationManager: authorizationManager,
        bluetoothNursery: bluetoothNursery
    )
    private lazy var statusStateMachine = StatusStateMachine(
        persisting: persistence,
        contactEventsUploader: contactEventsUploader,
        drawerMailbox: drawerMailbox,
        notificationCenter: notificationCenter,
        userNotificationCenter: userNotificationCenter,
        dateProvider: self.dateProvider
    )
    private lazy var drawerMailbox = DrawerMailbox(
        persistence: persistence
    )

    func resetTime() {
        mockedDate = Date()
    }

    func advanceTime(_ timeInterval: TimeInterval) {
        mockedDate = Date(timeInterval: timeInterval, since: mockedDate)
    }

    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .onboarding:
            let onboardingViewController = OnboardingViewController.instantiate { viewController in
                let remoteNotificationManager = EphemeralRemoteNotificationManager(
                    host: viewController,
                    authorizationManager: authorizationManager,
                    dispatcher: dispatcher
                )
                let env = OnboardingEnvironment(
                    persistence: persistence,
                    authorizationManager: authorizationManager,
                    remoteNotificationManager: remoteNotificationManager,
                    notificationCenter: notificationCenter
                )
                viewController.inject(
                    env: env,
                    coordinator: onboardingCoordinator,
                    bluetoothNursery: bluetoothNursery,
                    uiQueue: DispatchQueue.main
                ) { }
            }

            return onboardingViewController
            
        case .positiveTestStatus:
            statusStateMachine.received(TestResult(result: .positive, testTimestamp: dateProvider(), type: nil, acknowledgementUrl: nil))
            return createNavigationController()
            
        case .status:
            return createNavigationController()
            
        case .negativeTestSymptomatic:
            let startDate = Calendar.current.date(byAdding: .day, value: -3, to: dateProvider())!
            let checkinDate = Calendar.current.date(byAdding: .day, value: -1, to: dateProvider())!
            let symptomatic = StatusState.Symptomatic(symptoms: [], startDate: startDate, checkinDate: checkinDate)
            persistence.statusState = .symptomatic(symptomatic)

            let testTimestamp = Calendar.current.date(byAdding: .day, value: -2, to: dateProvider())!
            statusStateMachine.received(TestResult(result: .negative, testTimestamp: testTimestamp, type: nil, acknowledgementUrl: nil))
            return createNavigationController()
        }
    }
    
    func createNavigationController() -> UINavigationController {
        let statusViewController = StatusViewController.instantiate { viewController in
            viewController.inject(
                statusStateMachine: statusStateMachine,
                userStatusProvider: userStatusProvider,
                persistence: persistence,
                linkingIdManager: linkingIdManager,
                registrationService: registrationService,
                dateProvider: self.dateProvider,
                notificationCenter: notificationCenter,
                drawerMailbox: drawerMailbox,
                localeProvider: AutoupdatingCurrentLocaleProvider()
            )
        }
        let navigationController = UINavigationController()
        navigationController.pushViewController(statusViewController, animated: false)
        return navigationController
    }
}

private class InMemoryPersistence: Persisting {
    var delegate: PersistenceDelegate?

    var registration: Registration? = nil
    var potentiallyExposed: Date?
    var partialPostcode: String? = nil
    var bluetoothPermissionRequested: Bool = false
    var uploadLog: [UploadLog] = []
    var lastInstalledVersion: String?
    var lastInstalledBuildNumber: String?
    var registeredPushToken: String?
    var disabledNotificationsStatusView: Bool = false
    var acknowledgmentUrls: Set<URL> = []
    var statusState: StatusState = .ok(StatusState.Ok())
    var drawerMessages: [DrawerMessage] = []

    func clear() {
        registration = nil
        potentiallyExposed = nil
        partialPostcode = nil
        uploadLog = []
        lastInstalledVersion = nil
        lastInstalledBuildNumber = nil
        disabledNotificationsStatusView = false
        acknowledgmentUrls = []
        statusState = .ok(StatusState.Ok())
        drawerMessages = []
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

    func upload(from startDate: Date, with symptoms: Symptoms) throws {}
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
