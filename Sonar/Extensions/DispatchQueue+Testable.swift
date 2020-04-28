//
//  DispatchQueue+Testable.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol TestableQueue {
    func sync(execute block: () -> Void)
    func async(group: DispatchGroup?, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute work: @escaping @convention(block) () -> Void)
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void)
}

extension TestableQueue {
    public func async(group: DispatchGroup? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -> Void) {
        async(group: group, qos: qos, flags: flags, execute: work)
    }
}

extension DispatchQueue: TestableQueue {
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void) {
        asyncAfter(deadline: deadline, qos: .unspecified, flags: [], execute: execute)
    }
}
