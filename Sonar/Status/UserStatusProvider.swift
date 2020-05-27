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
    
    func detailWithExpiryDate(_ expiryDate: Date) -> String {
        let detailFmt = "On %@ this app will notify you to update your symptoms. Please read your full advice below.".localized
        return String(format: detailFmt, expiryDate.localizedDate(template: "MMMMd", localeProvider: localeProvider))
    }
}
