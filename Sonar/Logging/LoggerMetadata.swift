//
//  LoggerMetadata.swift
//  Sonar
//
//  Created by NHSX on 01/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging
import UIKit

extension Logger.Metadata {
    
    init(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        self.init()
        
        if let centrals = launchOptions?[.bluetoothCentrals] as? [String] {
            self["has-launch-events-for-listener"] = .array(centrals.map(Logger.MetadataValue.string))
        }
        if let peripherals = launchOptions?[.bluetoothPeripherals] as? [String] {
            self["has-launch-events-for-broadcaster"] = .array(peripherals.map(Logger.MetadataValue.string))
        }
    }
    
    init(dictionary: [AnyHashable : Any]) {
        self.init(uniqueKeysWithValues: dictionary
            .map { (key, value) in
                return ("\(key)", Logger.MetadataValue(describing: value))
            }
        )
    }
    
}

private extension Logger.MetadataValue {
    
    init(describing value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let array as [Any]:
            self = .array(array.map{ Logger.MetadataValue(describing: $0) })
        case let dictionary as [AnyHashable: Any]:
            self = .dictionary(Logger.Metadata(dictionary: dictionary))
        case let convertible as CustomStringConvertible:
            self = .stringConvertible(convertible)
        default:
            self = .string(String(describing: value))
        }
    }
    
}
