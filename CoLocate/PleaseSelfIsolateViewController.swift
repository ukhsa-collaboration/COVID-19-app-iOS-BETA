//
//  PleaseSelfIsolateViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PleaseSelfIsolateViewController: UIViewController {

    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningViewTitle: UILabel!
//    @IBOutlet weak var warningViewBody: UILabel!
    @IBOutlet weak var shareDiagnosisTitle: UILabel!
    @IBOutlet weak var shareDiagnosisBody: UILabel!
    @IBOutlet weak var shareDiagnosisButton: PrimaryButton!
    @IBOutlet weak var moreInformationTitle: UILabel!
    @IBOutlet weak var moreInformationBody: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .nhsGrey5
        warningView.backgroundColor = .nhsRed
        
        warningViewTitle.text = "You need to isolate yourself and stay at home"
        shareDiagnosisTitle.text = "Help us keep others safe"
        shareDiagnosisBody.text = "This app has recorded all contact you've had with other people using this app over the past 14 days.\n\nSharing this information with the NHS means we can notify these people to take steps to keep themselves safe."
        shareDiagnosisButton.setTitle("Notify", for: .normal)
        moreInformationTitle.text = "Steps you can take"
        moreInformationBody.text = "Based on people you've been in contact with, you may have been exposted to coronavirus.\n\nIf you're on public transport, go home by the most direct route. Stay at least 2 meters away from people if you can. If you're at home:\n\n• Find a room where you can close the door\n\n• Avoid touching people, surfaces and objects\n\nTo keep other people safe, don't visit your GP, pharmacy or hospital"
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
