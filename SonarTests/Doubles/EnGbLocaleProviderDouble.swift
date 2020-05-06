//
//  EnGbLocaleProviderDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/30/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class EnGbLocaleProviderDouble: LocaleProvider {
    var locale = Locale(identifier: "en_GB")
}
