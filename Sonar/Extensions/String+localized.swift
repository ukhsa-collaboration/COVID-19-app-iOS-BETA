//
//  String+localized.swift
//  Sonar
//
//  Created by NHSX on 25/03/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
