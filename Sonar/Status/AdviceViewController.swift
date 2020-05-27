//
//  AdviceViewController.swift
//  Sonar
//
//  Created by NHSX on 12/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AdviceViewController: UIViewController, Storyboarded {
    static let storyboardName = "Advice"

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var link: LinkButton!
    private var url: URL!
    private var expiryDate: Date?
    
    func inject(linkDestination: URL, expiryDate: Date?) {
        url = linkDestination
        self.expiryDate = expiryDate
    }
    
    override func viewDidLoad() {
        link.textStyle = .headline
        link.url = url
        
        if let expiryDate = expiryDate  {
            let localizedDate = expiryDate.localizedDate(template: "yyyyMMMMd", localeProvider: AutoupdatingCurrentLocaleProvider())
            detail.text = String(format: "ADVICE_VIEW_CONTROLLER_DETAIL_WITH_EXPIRY".localized, localizedDate)
        } else {
            detail.text = "ADVICE_VIEW_CONTROLLER_DETAIL_NO_EXPIRY".localized
        }
    }
}
