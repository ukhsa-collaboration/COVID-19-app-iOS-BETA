//
//  DateExtensions.swift
//  Sonar
//
//  Created by NHSX on 12.05.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension Date {
    
    var midday: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    var followingMidnightUTC: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: self)!)
    }
    
    var precedingMidnightUTC: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.startOfDay(for: self)
    }

}
