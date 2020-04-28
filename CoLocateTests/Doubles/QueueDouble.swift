//
//  QueueDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class QueueDouble: TestableQueue {
    var scheduledBlock: (() -> Void)?
    
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void) {
        scheduledBlock = execute
    }

    func async(group: DispatchGroup?, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute work: @escaping @convention(block) () -> Void) {
        work()
    }
    
    func sync(execute block: () -> Void) {
        block()
    }
}
