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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoStrapline.backgroundColor = UIColor.nhsBlue
        logoStraplineLabel.text = "Coronavirus"
        
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
