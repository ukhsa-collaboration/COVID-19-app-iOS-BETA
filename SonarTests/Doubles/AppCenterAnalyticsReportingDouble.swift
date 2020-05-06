//
//  AppCenterAnalyticsReportingDouble.swift
//  SonarTests
//
//  Created by NHSX on 01/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class AppCenterAnalyticsReportingDouble: AppCenterAnalyticsReporting {
    var trackedEvents = [(eventName: String, properties: [String : String]?)]()
    
    func trackEvent(_ eventName: String, withProperties properties: [String : String]?) {
        trackedEvents.append((eventName, properties))
    }
}
