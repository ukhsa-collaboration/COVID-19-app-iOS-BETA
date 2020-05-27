//
//  Date+localized.swift
//  Sonar
//
//  Created by NHSX on 27/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension Date {
    func localizedDate(template: String, localeProvider: LocaleProvider) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = localeProvider.locale
        dateFormatter.setLocalizedDateFormatFromTemplate(template)
        return dateFormatter.string(from: self)
    }
}
