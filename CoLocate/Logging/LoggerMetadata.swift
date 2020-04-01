//
//  LoggerMetadata.swift
//  CoLocate
//
//  Created by NHSX.
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
    
}
