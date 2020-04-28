//
//  AppMonitorDouble.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

struct AppMonitoringDouble: AppMonitoring {
    func didDetect(_ event: AppEvent) {
    }
}
