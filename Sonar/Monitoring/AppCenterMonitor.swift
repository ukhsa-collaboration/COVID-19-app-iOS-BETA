//
//  AppCenterMonitoring.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import AppCenter
import AppCenterAnalytics

protocol AppCenterAnalyticsReporting {
    func trackEvent(_ eventName: String, withProperties properties: [String : String]?)
}

struct AppCenterMonitor: AppMonitoring {
    
    private var reporter: AppCenterAnalyticsReporting?
    
    static let shared: AppCenterMonitor = {
        guard !Environment.appCenterKey.isEmpty else {
            return AppCenterMonitor(reporter: nil)
        }
        
        MSAppCenter.start(Environment.appCenterKey, withServices: [MSAnalytics.self])
        return AppCenterMonitor(reporter: AppCenterAnalyticsReporter())
    }()
    
    init(reporter: AppCenterAnalyticsReporting?) {
        self.reporter = reporter
    }
    
    func report(_ event: AppEvent) {
    }
}

private struct AppCenterAnalyticsReporter: AppCenterAnalyticsReporting {
    func trackEvent(_ eventName: String, withProperties properties: [String : String]?) {
        MSAnalytics.trackEvent(eventName, withProperties: properties)
    }
}
