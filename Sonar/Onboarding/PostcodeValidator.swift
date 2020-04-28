//
//  PostcodeValidator.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PostcodeValidator {
    static func isValid(_ postcode: String) -> Bool {
        return postcode.count >= 2 && postcode.count <= 4 && isAlphanumeric(s: postcode)
    }
    
}

private func isAlphanumeric(s: String) -> Bool {
    return s.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
}
