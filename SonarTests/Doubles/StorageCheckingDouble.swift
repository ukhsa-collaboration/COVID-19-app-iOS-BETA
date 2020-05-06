//
//  StorageCheckingDouble.swift
//  SonarTests
//
//  Created by NHSX on 04/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class StorageCheckingDouble: StorageChecking {
    var state = StorageState.notInitialized
    var markAsSyncedCallbackCount = 0
    
    func markAsSynced() {
        markAsSyncedCallbackCount += 1
    }
}
