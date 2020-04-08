//
//  StartNowViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class StartNowViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"
    
    lazy var environment = OnboardingEnvironment()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destination = segue.destination as? PrivacyViewController {
            destination.interactor = environment.privacyViewControllerInteractor
        }
    }
}
