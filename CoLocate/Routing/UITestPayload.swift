//
//  UITestPayload.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct UITestPayload: Codable {
    static let environmentVariableName = "UI_TEST_PAYLOAD"
    var screen: Screen
}
