//
//  LocaleProvider.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LocaleProvider {
    var locale: Locale { get }
}


class AutoupdatingCurrentLocaleProvider: LocaleProvider {
    var locale: Locale {
        get { return Locale.autoupdatingCurrent }
    }
}
