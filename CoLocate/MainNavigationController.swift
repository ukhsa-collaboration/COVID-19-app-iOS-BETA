//
//  MainNavigationController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController {
    var previouslyPresentedViewController: UIViewController?

    
    #if DEBUG || INTERNAL
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if let vc = presentedViewController {
            previouslyPresentedViewController = vc
            dismiss(animated: true)
        }

        if motion == UIEvent.EventSubtype.motionShake {
            showDebugView()
        }
    }

    @IBAction func unwindFromDebugViewController(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)

        if let vc = previouslyPresentedViewController {
            present(vc, animated: true)
        }
    }

    private func showDebugView() {
        let storyboard = UIStoryboard(name: "Debug", bundle: Bundle(for: Self.self))
        guard let debugVC = storyboard.instantiateInitialViewController() else { return }
        present(debugVC, animated: true)
    }
    #endif
}
