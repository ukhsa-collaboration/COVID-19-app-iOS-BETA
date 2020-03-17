//
//  PermissionsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

class PermissionsPromptViewController: UIViewController, BTLEBroadcasterDelegate, BTLEListenerDelegate {

    @IBOutlet weak var bodyHeadline: UILabel!
    @IBOutlet weak var bodyCopy: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
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
    
    private func segueIfBTLEReady() {
        if btleReady.broadcasterReady && btleReady.listenerReady {
            self.performSegue(withIdentifier: "enterDiagnosisSegue", sender: nil)
        }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
