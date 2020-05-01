//
//  AppEvent.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum AppEvent: Equatable {
    case partialPostcodeProvided
    case registrationSucceeded
    case registrationFailed
    case onboardingCompleted
    case collectedContactEvents(yesterday: Int, all: Int)
}
