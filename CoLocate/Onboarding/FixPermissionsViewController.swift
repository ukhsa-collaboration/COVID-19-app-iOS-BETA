//
//  PermissionDeniedViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

// Base class for view controllers that ask the user to fix a permissions problem.
class FixPermissionsViewController: UIViewController {
    
    private var notificationCenter: NotificationCenter!
    private var uiQueue: TestableQueue!
    private var continueHandler: (() -> Void)?
    
    func inject(notificationCenter: NotificationCenter, uiQueue: TestableQueue, continueHandler: (() -> Void)?) {
        self.notificationCenter = notificationCenter
        self.uiQueue = uiQueue
        self.continueHandler = continueHandler
    }
    
    deinit {
        notificationCenter?.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if continueHandler != nil {
            notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
                self.uiQueue.async {
                    self.continueHandler!()
                }
            }
        }
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }

}
