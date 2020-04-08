//
//  UITestScreenMaker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if INTERNAL || DEBUG

struct UITestScreenMaker: ScreenMaking {
    
    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .potential:
            let viewController = UIViewController()
            viewController.title = "Potential"
            return UINavigationController(rootViewController: viewController)
        case .onboarding:
            return OnboardingViewController.instantiate {
                $0.environment = OnboardingEnvironment(mockWithHost: $0)
                // TODO: Remove this – currently needed to kick `updateState()`
                $0.rootViewController = nil
            }
        }
    }
    
}

private extension OnboardingEnvironment {
    
    convenience init(mockWithHost host: UIViewController) {
        self.init(
            persistence: InMemoryPersistence(host: host)
        )
    }
    
}

private class InMemoryPersistence: Persisting {
    
    weak var host: UIViewController?
    init(host: UIViewController) {
        self.host = host
    }
    
    var allowedDataSharing = false {
        didSet {
            if allowedDataSharing {
                didAllowDataSharing()
            }
        }
    }
    var registration: Registration? = nil
    var diagnosis = Diagnosis.unknown
    
    func didAllowDataSharing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            let alert = UIAlertController(title: "Recorded data sharing consent", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.host?.present(alert, animated: false, completion: nil)
        }
    }

}

#endif
