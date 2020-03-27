//
//  RootViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RootViewController: UINavigationController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        get { return true }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if presentedViewController == nil && motion == UIEvent.EventSubtype.motionShake {
            print("showing")
            showDebugView()
        }
    }
    
        
    private func showDebugView() {
        let storyboard = UIStoryboard(name: "Debug", bundle: nil)
        let debugVC = storyboard.instantiateInitialViewController() as! DebugViewController
        debugVC.delegate = self
        self.present(debugVC, animated: true)
    }
}

extension RootViewController: DebugViewControllerDelegate {
    func debugViewControllerWantsToExit(_ sender: DebugViewController) -> Void {
        dismiss(animated: true)
    }
}
