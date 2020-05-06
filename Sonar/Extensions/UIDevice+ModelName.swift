//
//  UIDevice+ModelName.swift
//  Sonar
//
//  Created by NHSX on 06.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

extension UIDevice {
    
    // From https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios
    // CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

}
