//
//  PermissionsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

class PermissionsPromptViewController: UIViewController, BTLEBroadcasterDelegate, BTLEListenerDelegate, Storyboarded {
    static let storyboardName = "Permissions"
    var coordinator: AppCoordinator?

    @IBOutlet private var bodyHeadline: UILabel!
    @IBOutlet private var bodyCopy: UILabel!
    @IBOutlet private var continueButton: UIButton!
    
    private var btleReady: (listenerReady: Bool, broadcasterReady: Bool) = (false, false)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bodyHeadline.text = "Permissions we need"
        bodyCopy.text = """
        To trace people you come in contact with, this app will automatically access:
        
        • Bluetooth, to record when your device is near others who are using this app
        """

        continueButton.setTitle("I understand", for: .normal)
    }
    
    @IBAction func didTapContinue(_ sender: UIButton) {
        segueIfBTLEReady()
      #if targetEnvironment(simulator)
        btleReady.broadcasterReady = true
        btleReady.listenerReady = true
        segueIfBTLEReady()
      #else
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        appDelegate.broadcaster = BTLEBroadcaster()
        appDelegate.broadcaster?.start(delegate: self)

        appDelegate.listener = BTLEListener()
        appDelegate.listener?.start(delegate: self)
      #endif
    }

    // MARK: BTLEBroadcasterDelegate / BTLEListenerDelegate

    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState) {
        if state == .poweredOn {
            btleReady.broadcasterReady = true
        }
        segueIfBTLEReady()
    }

    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState) {
        if state == .poweredOn {
            btleReady.listenerReady = true
        }
        segueIfBTLEReady()
    }

    private func segueIfBTLEReady() {
        if btleReady.broadcasterReady && btleReady.listenerReady {
            coordinator?.showViewAfterPermissions()
        }
    }
}
