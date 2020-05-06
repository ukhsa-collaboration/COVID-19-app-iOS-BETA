//
//  DataExtensions.swift
//  Sonar
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    var networkByteOrderData: Data {
        var mutableSelf = self.bigEndian // network byte order
        return Data(bytes: &mutableSelf, count: MemoryLayout.size(ofValue: mutableSelf))
    }
}

// from https://stackoverflow.com/a/38024025/17294
// CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
extension Data {

    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
}
