//
//  ContactEventsUploader.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

class ContactEventsUploader {

    static let backgroundIdentifier = "ContactEventUploader"

    let sessionDelegate: ContactEventsUploaderSessionDelegate = ContactEventsUploaderSessionDelegate()

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

        sessionDelegate.contactEventsUploader = self
    }

    func upload() throws {
        persisting.uploadLog = persisting.uploadLog + [UploadLog(event: .requested)]

        guard let registration = persisting.registration else {
            // upload-contact-events-in-background: handle when we have no registration
            return
        }

        let contactEvents = contactEventRepository.contactEvents
        let lastDate = contactEvents.map { $0.timestamp }.max() ?? Date() // conservatively default to the current time
        persisting.uploadLog = persisting.uploadLog + [UploadLog(event: .started(lastContactEventDate: lastDate))]

        let requestFactory = ConcreteSecureRequestFactory(registration: registration)
        let request = requestFactory.patchContactsRequest(contactEvents: contactEvents)

        try session.upload(with: request)
    }

    func cleanup() {
        let lastDate = persisting.uploadLog
            .compactMap { log in
                guard case .started(let date) = log.event else { return nil }
                return date
            }
            .max() ?? Date() // conservatively default to removing everything if we somehow don't have a started log

        contactEventRepository.remove(through: lastDate)
    }

}

// We need to pass the URLSession delegate when we create the URLSession, so this
// creates a catch-22 that we resolve by having this separate delegate object be
// initialized first.
class ContactEventsUploaderSessionDelegate: NSObject, URLSessionTaskDelegate {

    let logger = Logger(label: "ContactEventsUploaderSessionDelegate")

    fileprivate var contactEventsUploader: ContactEventsUploader!
    var completionHandler: (() -> Void)?

//    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//        print(#file, #function, task, "bytesSent: \(bytesSent), totalBytesSent: \(totalBytesSent), totalBytesExpectedToSend: \(totalBytesExpectedToSend)")
//    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            // upload-contact-events-in-background: retry?
            return
        }

        // upload-contact-events-in-background: check server response
        contactEventsUploader.cleanup()

        print(#file, #function, task)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background

        DispatchQueue.main.async {
            self.completionHandler?()
        }
    }

}
