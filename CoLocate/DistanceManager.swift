//
//  DistanceManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

// Calculates distances from bluetooth rssi
// tested to be more accurate than Apple's default algorithm!
class DistanceManager {
    // values from testing in the lab
    let rssi1m:Int = -46 // "immediate"
    let rssi3m:Int = -60 // "near"
    // lower = "far"
    let rssiUnknown = 0 // "unknown"
    //let rssi5m:Int = -65 // unused
    
    let maxReadings = 5
    
    var readings = Dictionary<String,Array<Int>>()
    var ranges = Dictionary<String,String>()
    
    func addDistance(remoteID:String,rssi:Int) -> String {
        if (0 == rssi) {
            if let rg = ranges[remoteID] {
                return rg
            } else {
                return "unknown"
            }
        }
        // get distance collection for remoteID
        if var values = readings[remoteID] {
            values.append(rssi)
            if values.count > maxReadings {
                values.remove(at:0)
            }
            readings[remoteID] = values
        } else {
            readings[remoteID] = Array<Int>([rssi])
        }
        // Calculate running average for distance
        if let values = readings[remoteID] {
            var runningTotal = 0
            for value in values {
                runningTotal += value
                print("value: \(value)")
            }
            let avg = runningTotal / values.count
            print("avg: \(avg)")
            if (rssiUnknown == avg) {
                ranges[remoteID] = "unknown"
            } else if avg >= rssi1m {
                ranges[remoteID] = "immediate"
            } else if avg >= rssi3m {
                ranges[remoteID] = "near"
            } else {
                ranges[remoteID] = "far"
            }
        }
        return ranges[remoteID]!
    }
    
    func removeAll(except: Array<String>) {
        // used to remove ID's we've not heard from
        for key in readings.keys {
            if !except.contains(key) {
                readings.removeValue(forKey: key)
                ranges.removeValue(forKey: key)
            }
        }
    }
    
    var detected: Dictionary<String,String> {
        get {
            return ranges
        }
    }
    
}
