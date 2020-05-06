//
//  File.swift
//  Sonar
//
//  Created by NHSX on 23/03/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

struct RequestFactory {

    static func registrationRequest(pushToken: String) -> RegistrationRequest {
        return RegistrationRequest(pushToken: pushToken)
    }
    
    static func confirmRegistrationRequest(activationCode: String, pushToken: String, postalCode: String) -> ConfirmRegistrationRequest {
        let deviceModel = UIDevice.current.modelName
        let deviceOSVersion = UIDevice.current.systemVersion

        return ConfirmRegistrationRequest(activationCode: activationCode,
                                          pushToken: pushToken,
                                          deviceModel: deviceModel, deviceOSVersion: deviceOSVersion,
                                          postalCode: postalCode)
    }
}
