//
//  ContactEventsUploaderDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class ContactEventsUploaderDouble: ContactEventsUploader {
    init() {
        super.init(
            persisting: PersistenceDouble(),
            contactEventRepository: ContactEventRepositoryDouble(),
            trustValidator: TrustValidatingDouble(),
            makeSession: { _, _ in SessionDouble() }
        )
    }

    var uploadCalled = false
    override func upload() throws {
        uploadCalled = true
    }
}
