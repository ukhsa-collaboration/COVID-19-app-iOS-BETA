//
//  AppEvent.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum AppEvent: Equatable {
    enum RegistrationFailureReason {
        case waitingForFCMTokenTimedOut
        case registrationCallFailed
        case waitingForActivationNotificationTimedOut
        case activationCallFailed
    }
    case partialPostcodeProvided
    case onboardingCompleted
    case registrationSucceeded
    case registrationFailed(reason: RegistrationFailureReason)
    case collectedContactEvents(yesterday: Int, all: Int)
}
