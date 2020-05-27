//
//  UserStatusProvider.swift
//  Sonar
//
//  Created by NHSX on 14/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class UserStatusProvider {
    let localeProvider: LocaleProvider
    init(localeProvider: LocaleProvider) {
        self.localeProvider = localeProvider
    }

    private func localizedDate(_ date: Date, _ template: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = localeProvider.locale
        dateFormatter.setLocalizedDateFormatFromTemplate(template)
        return dateFormatter.string(from: date)
    }
    
    func detailWithExpiryDate(_ expiryDate: Date) -> String {
        let detailFmt = "On %@ this app will notify you to update your symptoms. Please read your full advice below.".localized
        return String(format: detailFmt, localizedDate(expiryDate, "MMMMd"))
    }
}
