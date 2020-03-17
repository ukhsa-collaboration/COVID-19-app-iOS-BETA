//
//  OkNowViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class OkNowViewController: UIViewController {

    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningViewTitle: UILabel!
    @IBOutlet weak var warningViewBody: UILabel!
    @IBOutlet weak var checkSymptomsTitle: UILabel!
    @IBOutlet weak var checkSymptomsBody: UILabel!
    @IBOutlet weak var moreInformationTitle: UILabel!
    @IBOutlet weak var moreInformationBody: UILabel!
    @IBOutlet weak var checkSymptomsButton: PrimaryButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        warningView.backgroundColor = .nhsWarmYellow
        
        warningViewTitle.text = "You're ok right now"
        warningViewBody.text = "This is a real time status, based on who you've been in contact with.\n\nYou'll get an alert if your status changes.\n\nIt is important to tell us if you develop any new symptoms."
        checkSymptomsTitle.text = "If you develop symptoms"
        checkSymptomsBody.text = "Use our online tool to check your symptoms."
        checkSymptomsButton.setTitle("Check my symptoms", for: .normal)
        moreInformationTitle.text = "How you can protect yourself and others"
        moreInformationBody.text = "You can stay safe by washing your hands more regularly and avoiding large groups of people.\n\nVisit NHS 111 for more advice on protecting yourself and people you care about.\n\nThank you for helping us slow the spread of coronavirus"
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
