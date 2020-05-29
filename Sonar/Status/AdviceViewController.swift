//
//  AdviceViewController.swift
//  Sonar
//
//  Created by NHSX on 12/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

fileprivate extension StatusState {
    var adviceUntilDate: Date? {
        switch self {
        case .ok:
             return nil
        case .exposed(let state):
            return state.expiryDate
        case .positiveTestResult(let state):
            return state.expiryDate
        case .symptomatic(let state):
            return state.checkinDate
        case .exposedSymptomatic(let state):
            return state.checkinDate
        }
    }
}

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
        link.textStyle = .headline
        link.url = ContentURLs.shared.currentAdvice(for: state)
        
        if let adviceUntilDate = state.adviceUntilDate {
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
