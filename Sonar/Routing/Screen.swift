//
//  Screen.swift
//  Sonar
//
//  Created by NHSX on 03/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

#if DEBUG

enum Screen: String, Codable {
    
    // Flows
    case onboarding

    case status
    
    case positiveTestStatus

    case negativeTestSymptomatic
    
    case exposedStatus
}

#endif
