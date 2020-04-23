//
//  ContactEventsUploader.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class ContactEventsUploader {

    static let backgroundIdentifier = "ContactEventUploader"

    let sessionDelegate: URLSessionTaskDelegate = ContactEventsUploaderSessionDelegate()

    let persisting: Persisting
    let contactEventRepository: ContactEventRepository
    let session: Session

    init(
        persisting: Persisting,
        contactEventRepository: ContactEventRepository,
        makeSession: (String, URLSessionTaskDelegate) -> Session
    ) {
        self.persisting = persisting
        self.contactEventRepository = contactEventRepository
        self.session = makeSession(ContactEventsUploader.backgroundIdentifier, sessionDelegate)
    }

    func upload() throws {
        let contactEvents = contactEventRepository.contactEvents

        guard let registration = persisting.registration else {
            fatalError("upload-contact-events-in-background: handle when we have no registration")
        }
        let requestFactory = ConcreteSecureRequestFactory(registration: registration)
        let request = requestFactory.patchContactsRequest(contactEvents: contactEvents)

        try session.upload(with: request)
    }

}

// This class exists due to the catch-22 of needing to provide the
// URLSessionDelegate in the initialization of the URLSession.
fileprivate class ContactEventsUploaderSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // upload-contact-events-in-background: might be useful for debugging
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // upload-contact-events-in-background: delete upload file
        // upload-contact-events-in-background: delete uploaded contact events
        // upload-contact-events-in-background: handle errors
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background

        // upload-contact-events-in-background: is this called for upload tasks?
    }
}
