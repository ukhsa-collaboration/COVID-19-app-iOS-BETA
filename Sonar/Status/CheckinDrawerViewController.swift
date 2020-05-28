//
//  CheckinPromptViewController.swift
//  Sonar
//
//  Created by NHSX on 4/20/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class CheckinDrawerViewController: UIViewController, Storyboarded {
    static var storyboardName = "CheckinDrawer"

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var detail: UILabel!
    private var headerText: String?
    private var detailText: String?
    var completion: ((_ needsCheckin: Bool) -> Void)!

    func inject(
        headerText: String,
        detailText: String,
        completion: @escaping (_ needsCheckin: Bool) -> Void
    ) {
        self.completion = completion
        self.headerText = headerText
        self.detailText = detailText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        header.text = headerText
        detail.text = detailText
    }
    
    @IBAction func updateSymptoms() {
        completion(true)
    }
    
    @IBAction func noSymptoms() {
        completion(false)
    }
}
