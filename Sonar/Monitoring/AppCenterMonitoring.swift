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

struct AppCenterMonitoring: AppMonitoring {
    
    init() {
        if Environment.appCenterKey.isEmpty { return }
        MSAppCenter.start(Environment.appCenterKey, withServices: [MSAnalytics.self])
    }
    
    func report(_ event: AppEvent) {
        
    }
}
