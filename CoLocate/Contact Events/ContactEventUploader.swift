//
//  ContactEventUploader.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class ContactEventUploader {

    static let backgroundIdentifier = "ContactEventUploader"

    let sessionDelegate: URLSessionTaskDelegate = ContactEventUploaderSessionDelegate()
    let contactEventRepository: ContactEventRepository
    let session: Session

    init(contactEventRepository: ContactEventRepository, makeSession: (String, URLSessionTaskDelegate) -> Session) {
        self.contactEventRepository = contactEventRepository
        self.session = makeSession(ContactEventUploader.backgroundIdentifier, sessionDelegate)
    }

    //  upload-contact-events-in-background: we can't require registration here
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

// This exists due to the catch-22 of needing to provide the URLSessionDelegate
// in the initialization of the URLSession.
fileprivate class ContactEventUploaderSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // upload-contact-events-in-background: delete uploaded contact events
        // upload-contact-events-in-background: handle errors
    }
}
