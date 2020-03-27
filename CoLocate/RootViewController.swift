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
        if presentedViewController == nil && motion == UIEvent.EventSubtype.motionShake && DebugSetting.enabled {
            showDebugView()
        }
    }

    private func showDebugView() {
        let storyboard = UIStoryboard(name: "Debug", bundle: nil)
        guard let debugVC = storyboard.instantiateInitialViewController() else { return }
        self.present(debugVC, animated: true)
    }

    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, sender: Any?) -> Bool {
        return type(of: fromViewController) == DebugViewController.self
    }

    @IBAction func unwindFromDebugViewController(unwindSegue: UIStoryboardSegue) {
    }

}
