//
//  DefaultObjectStoringDouble.swift
//  SonarTests
//
//  Created by NHSX on 01/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class DefaultObjectStoringDouble: DefaultObjectStoring {
    var objects = [String: Any]()
    
    func set(_ value: Any?, forKey defaultName: String) {
        objects[defaultName] = value
    }
    
    func object(forKey defaultName: String) -> Any? {
        objects[defaultName]
    }
}
