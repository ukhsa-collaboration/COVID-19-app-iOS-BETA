//
//  UITestPayload.swift
//  Sonar
//
//  Created by NHSX on 03/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct UITestPayload: Codable {
    static let environmentVariableName = "UI_TEST_PAYLOAD"
    var screen: Screen
}
