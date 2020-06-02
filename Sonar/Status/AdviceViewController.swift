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
    private var state: StatusState!
    private var localeProvider: LocaleProvider!
    
    func inject(state: StatusState, localeProvider: LocaleProvider) {
        self.state = state
        self.localeProvider = localeProvider
    }
    
    override func viewDidLoad() {
        link.url = ContentURLs.shared.currentAdvice(for: state)
        
        if let adviceUntilDate = state.endDate {
            detail.text = "The advice below is up-to-date and specific to your situation. Follow this advice until \(localizedDate(adviceUntilDate, "d MMMM y"))."
        } else {
            detail.text = "The advice below is up-to-date and specific to your situation. Please follow this advice."
        }
    }
    
    private func localizedDate(_ date: Date, _ template: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = localeProvider.locale
        dateFormatter.dateStyle = .none
        dateFormatter.setLocalizedDateFormatFromTemplate(template)
        return dateFormatter.string(from: date)
    }
}
