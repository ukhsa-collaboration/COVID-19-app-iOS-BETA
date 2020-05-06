//
//  PostcodeValidator.swift
//  SonarTests
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PostcodeValidator {
    static func isValid(_ postcode: String) -> Bool {
        return postcode.range(of: "^[A-Z]{1,2}[0-9R][0-9A-Z]?$", options: .regularExpression) != nil
    }
}
