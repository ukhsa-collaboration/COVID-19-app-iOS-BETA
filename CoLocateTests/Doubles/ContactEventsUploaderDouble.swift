//
//  ContactEventsUploaderDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import CoLocate

class ContactEventsUploaderDouble: ContactEventsUploader {
    init() {
        super.init(
            persisting: PersistenceDouble(),
            contactEventRepository: ContactEventRepositoryDouble(),
            trustValidator: DefaultTrustValidating(),
            makeSession: { _, _ in SessionDouble() }
        )
    }

    var uploadCalled = false
    override func upload() throws {
        uploadCalled = true
    }
}
