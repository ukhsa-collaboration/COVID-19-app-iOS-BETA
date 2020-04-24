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
        contactEventsUploader: ContactEventsUploader
    ) {
        let coordinator = SelfDiagnosisCoordinator(
            navigationController: self,
            persisting: persistence,
            contactEventRepository: contactEventRepo,
            session: session
        )
        coordinator.start()
    }
}
