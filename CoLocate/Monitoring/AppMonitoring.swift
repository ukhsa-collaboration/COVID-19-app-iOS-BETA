//
//  AppMonitoring.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol AppMonitoring {
    func didDetect(_ event: AppEvent)
}

struct NoOpAppMonitoring: AppMonitoring {
    func didDetect(_ event: AppEvent) {
    }
}
