//
//  BluetoothPermissionDeniedViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BluetoothPermissionDeniedViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"
    
    private var notificationCenter: NotificationCenter!
    private var uiQueue: TestableQueue!
    private var continueHandler: (() -> Void)!
    
    func inject(notificationCenter: NotificationCenter, uiQueue: TestableQueue, continueHandler: @escaping () -> Void) {
        self.notificationCenter = notificationCenter
        self.uiQueue = uiQueue
        self.continueHandler = continueHandler
    }
    
    deinit {
        notificationCenter?.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            self.uiQueue.async {
                self.continueHandler()
            }
        }
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }

}
