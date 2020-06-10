//
//  BundleExtensions.swift
//  Sonar
//
//  Created by NHSX on 10.06.20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

extension Bundle {
    var versionString: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown"
        return "Version \(version) (build \(build))"
    }
}
