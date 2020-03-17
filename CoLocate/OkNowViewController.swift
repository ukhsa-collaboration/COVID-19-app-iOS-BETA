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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        warningView.backgroundColor = .nhsWarmYellow
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
