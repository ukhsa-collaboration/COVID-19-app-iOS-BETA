//
//  LogEvent.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct LogEvent {
    var label: String
    var level: Logger.Level
    var message: Logger.Message
    var metadata: Logger.Metadata?
    var date: Date
    var file: String
    var function: String
    var line: UInt
}
