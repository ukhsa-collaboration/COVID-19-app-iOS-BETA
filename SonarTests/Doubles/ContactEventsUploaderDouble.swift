//
//  ContactEventsUploaderDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
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

    var uploadStartDate: Date?
    override func upload(from startDate: Date) throws {
        uploadStartDate = startDate
    }
}
