//
//  AppMonitorDouble.swift
//  Sonar
//
//  Created by NHSX on 28/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class AppMonitoringDouble: AppMonitoring {
    
    var detectedEvents = [AppEvent]()
    
    func report(_ event: AppEvent) {
        detectedEvents.append(event)
    }
}
