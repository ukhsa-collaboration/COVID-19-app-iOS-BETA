//
//  UUIDExtensions.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension UUID {
    
    init?(data: Data) {
        guard data.count == 16 else {
            return nil
        }
        
        let uuid: uuid_t = (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15])
        self.init(uuid: uuid)
    }

    var data: Data {
        return withUnsafePointer(to: uuid) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: uuid))
        }
    }

}
