//
//  ContactEventUploader.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class ContactEventUploader {

    let contactEventRepository: ContactEventRepository
    let session: Session

    init(contactEventRepository: ContactEventRepository, session: Session) {
        self.contactEventRepository = contactEventRepository
        self.session = session
    }

    func upload(with registration: Registration) throws {
        let contactEvents = contactEventRepository.contactEvents

        let requestFactory = ConcreteSecureRequestFactory(registration: registration)
        let request = requestFactory.patchContactsRequest(contactEvents: contactEvents)

        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("contactEvents.json")

        try request.urlRequest().httpBody!.write(to: fileURL)

        session.upload(with: request, fromFile: fileURL)
    }

}
