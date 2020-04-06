//
//  DispatchQueue+AsyncAfterable.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol AsyncAfterable {
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void)
}

extension DispatchQueue: AsyncAfterable {
    func asyncAfter(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void) {
        asyncAfter(deadline: deadline, qos: .unspecified, flags: [], execute: execute)
    }    
}
