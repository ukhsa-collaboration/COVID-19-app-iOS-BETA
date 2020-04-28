//
//  AppMonitorDouble.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class AppMonitoringDouble: AppMonitoring {
    
    var detectedEvents = [AppEvent]()
    
    func didDetect(_ event: AppEvent) {
        detectedEvents.append(event)
    }
}
