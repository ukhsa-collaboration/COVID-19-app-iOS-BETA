//
//  PermissionsPromptViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PermissionsPromptViewController: UIViewController {

    @IBOutlet weak var logoStrapline: UIView!
    @IBOutlet weak var logoStraplineLabel: UILabel!
    @IBOutlet weak var bodyHeadline: UILabel!
    @IBOutlet weak var bodyCopy: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoStrapline.backgroundColor = .nhsBlue
        logoStraplineLabel.textColor = .white
        logoStraplineLabel.text = "Coronavirus tracing"
        bodyHeadline.text = "Permissions we need"
        bodyCopy.text = """
        To trace people you come in contact with, this app will automatically access:
        
        • Bluetooth, to record when your device is near others who are using this app
        """
        continueButton.layer.cornerRadius = 4
        continueButton.clipsToBounds = true
        continueButton.backgroundColor = .nhsButton
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitle("I understand", for: .normal)
    }
    
    @IBAction func didTapContinue(_ sender: UIButton) {
      #if targetEnvironment(simulator)
      #else
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        appDelegate.broadcaster = BTLEBroadcaster()
        appDelegate.broadcaster?.start()
        
        appDelegate.listener = BTLEListener()
        appDelegate.listener?.start()
      #endif

      self.performSegue(withIdentifier: "areYouInfectedSegue", sender: nil)
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
