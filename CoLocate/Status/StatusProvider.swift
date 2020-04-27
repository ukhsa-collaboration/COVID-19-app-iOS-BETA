//
//  StatusProvider.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Status: Equatable {
    case blue, amber, red
}

class StatusProvider {

    var status: Status {
        .blue
    }

}
