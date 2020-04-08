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
                let environment = OnboardingEnvironment(mockWithHost: viewController)
                viewController.environment = environment
                viewController.didComplete = { [weak viewController] in
                    let summary = OnboardingStateSummaryViewController(environment: environment)
                    viewController?.present(summary, animated: false, completion: nil)
                }
                
                // TODO: Remove this – currently needed to kick `updateState()`
                viewController.rootViewController = nil
            }
        }
    }
    
}

private extension OnboardingEnvironment {
    
    convenience init(mockWithHost host: UIViewController) {
        // TODO: Fix initial state of mocks.
        // Currently it’s set so that onboarding is “done” as soon as we allow data sharing – so we can have a minimal
        // UI test.
        self.init(
            persistence: InMemoryPersistence(),
            authorizationManager: EphemeralAuthorizationManager()
        )
    }
    
}

private class InMemoryPersistence: Persisting {
    
    var allowedDataSharing = false
    var registration: Registration? = Registration(id: UUID(), secretKey: Data())
    var diagnosis = Diagnosis.unknown

}

private class EphemeralAuthorizationManager: AuthorizationManaging {
    var bluetooth: AuthorizationStatus = .allowed
    func notifications(completion: @escaping (AuthorizationStatus) -> Void) {
        completion(.allowed)
    }
}

#endif
