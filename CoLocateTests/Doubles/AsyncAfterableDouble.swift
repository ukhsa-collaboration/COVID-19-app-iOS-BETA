//
//  AsyncAfterableDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class AsyncAfterableDouble: AsyncAfterable {
    var scheduledBlock: (() -> Void)?
    
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void) {
        scheduledBlock = execute
    }
}
