//
//  UITestScreenMaker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

#if INTERNAL || DEBUG

import UIKit

struct UITestScreenMaker: ScreenMaking {
    
    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .potential:
            let viewController = UIViewController()
            viewController.title = "Potential"
            return UINavigationController(rootViewController: viewController)
        case .onboarding:
            return OnboardingViewController.instantiate { viewController in
                let env = OnboardingEnvironment(mockWithHost: viewController)
                let coordinator = OnboardingCoordinator(persistence: env.persistence, authorizationManager: env.authorizationManager)
                viewController.inject(env: env, coordinator: coordinator, uiQueue: DispatchQueue.main) { }
                
            }
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
    var allowedDataSharing = false
    var registration: Registration? = Registration(id: UUID(), secretKey: Data())
    var potentiallyExposed: Bool = false
    var selfDiagnosis: SelfDiagnosis? = nil
    var enableNewSelfDiagnosis = false
    var partialPostcode: String? = nil
    var enableNewKeyRotation = false
    
    func clear() {
        allowedDataSharing = false
        registration = nil
        selfDiagnosis = nil
        partialPostcode = nil
    }
}

private class EphemeralAuthorizationManager: AuthorizationManaging {
    var bluetooth = AuthorizationStatus.allowed
    var notificationsStatus = AuthorizationStatus.notDetermined
    func notifications(completion: @escaping (AuthorizationStatus) -> Void) {
        completion(notificationsStatus)
    }
}

private class EphemeralRemoteNotificationManager: RemoteNotificationManager {
    
    let dispatcher: RemoteNotificationDispatcher
    private let authorizationManager: EphemeralAuthorizationManager
    private weak var host: UIViewController?
    
    var pushToken: String? = nil
    
    init(host: UIViewController, authorizationManager: EphemeralAuthorizationManager, dispatcher: RemoteNotificationDispatcher) {
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

#endif
