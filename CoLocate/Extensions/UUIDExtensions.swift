//
//  UUIDExtensions.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension UUID {
    
    var data: Data {
        return withUnsafePointer(to: uuid) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: uuid))
        }
    }
    
//    init?(data: Data) {
//        guard data.count == 16 else {
//            return nil
//        }
//        data.withUnsafeBytes { ptr in
//            self.init(uuid: ptr)
//        }
//    }

}
