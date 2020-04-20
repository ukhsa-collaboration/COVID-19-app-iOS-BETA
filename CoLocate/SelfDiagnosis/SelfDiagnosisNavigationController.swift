//
//  SelfDiagnosisNavigationController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SelfDiagnosisNavigationController: UINavigationController, Storyboarded {
    static let storyboardName = "SelfDiagnosis"

    func inject(
        persistence: Persisting,
        contactEventRepo: ContactEventRepository,
        session: Session
    ) {
        let temperatureVC = viewControllers.first as! TemperatureViewController
        temperatureVC.inject(
            persistence: persistence,
            contactEventRepo: contactEventRepo,
            session: session
        )
    }
}
