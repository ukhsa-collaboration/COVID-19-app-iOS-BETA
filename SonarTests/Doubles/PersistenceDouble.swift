//
//  PersistenceDouble.swift
//  SonarTests
//
//  Created by NHSX on 3/27/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class PersistenceDouble: Persisting {
    var delegate: PersistenceDelegate?

    var registration: Registration?
    var potentiallyExposed: Date?
    var partialPostcode: String?
    var bluetoothPermissionRequested: Bool
    var uploadLog: [UploadLog]
    var lastInstalledVersion: String?
    var lastInstalledBuildNumber: String?
    var registeredPushToken: String?
    var disabledNotificationsStatusView: Bool
    var acknowledgmentUrls: Set<URL>
    var statusState: StatusState

    init(
        potentiallyExposed: Date? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil,
        bluetoothPermissionRequested: Bool = false,
        uploadLog: [UploadLog] = [],
        linkingId: LinkingId? = nil,
        lastInstalledVersion: String? = nil,
        lastInstalledBuildNumber: String? = nil,
        registeredPushToken: String? = nil,
        disabledNotificationsStatusView: Bool = false,
        acknowledgmentUrls: Set<URL> = [],
        statusState: StatusState = .ok(StatusState.Ok())
    ) {
        self.registration = registration
        self.potentiallyExposed = potentiallyExposed
        self.partialPostcode = partialPostcode
        self.potentiallyExposed = potentiallyExposed
        self.bluetoothPermissionRequested = bluetoothPermissionRequested
        self.uploadLog = uploadLog
        self.lastInstalledVersion = lastInstalledVersion
        self.lastInstalledBuildNumber = lastInstalledBuildNumber
        self.registeredPushToken = registeredPushToken
        self.disabledNotificationsStatusView = disabledNotificationsStatusView
        self.acknowledgmentUrls = acknowledgmentUrls
        self.statusState = statusState
    }

    func clear() {
        registration = nil
        partialPostcode = nil
        potentiallyExposed = nil
        bluetoothPermissionRequested = false
        uploadLog = []
        lastInstalledVersion = nil
        lastInstalledBuildNumber = nil
        registeredPushToken = nil
        acknowledgmentUrls = []
        statusState = .ok(StatusState.Ok())
    }
}
