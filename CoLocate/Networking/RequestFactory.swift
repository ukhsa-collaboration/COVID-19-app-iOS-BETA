//
//  File.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct RequestFactory {

    static func registrationRequest(pushToken: String) -> RegistrationRequest {
        return RegistrationRequest(pushToken: pushToken)
    }
    
    static func confirmRegistrationRequest(activationCode: String, pushToken: String) -> ConfirmRegistrationRequest {
        return ConfirmRegistrationRequest(activationCode: activationCode, pushToken: pushToken)
    }
}
