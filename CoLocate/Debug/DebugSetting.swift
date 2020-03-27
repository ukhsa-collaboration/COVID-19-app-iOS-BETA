//
//  DebugSetting.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DebugSetting {
    static let key = "debug_view_enabled_preference"
    
    static var enabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key)
        }
    }
}
