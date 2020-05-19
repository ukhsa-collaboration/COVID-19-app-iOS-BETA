//
//  ContactEventsUploader.swift
//  Sonar
//
//  Created by NHSX on 4/22/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

protocol ContactEventsUploading {
    var sessionDelegate: ContactEventsUploaderSessionDelegate { get }

    func upload(from startDate: Date, with symptoms: Symptoms) throws
    func cleanup()
    func error(_ error: Swift.Error)
    func ensureUploading() throws
}

class ContactEventsUploader: ContactEventsUploading {

    enum Error: Swift.Error {
        case rateLimited
        case server

        var localizedDescription: String {
            switch self {
            case .rateLimited: return "Rate Limited"
            case .server: return "Server Error"
            }
        }
    }

    static let backgroundIdentifier = "ContactEventUploader"

    let sessionDelegate: ContactEventsUploaderSessionDelegate

    let persisting: Persisting
    let contactEventRepository: ContactEventRepository
    let session: Session

    init(
        persisting: Persisting,
        contactEventRepository: ContactEventRepository,
        trustValidator: TrustValidating,
        makeSession: (String, URLSessionTaskDelegate) -> Session
    ) {
        self.persisting = persisting
        self.contactEventRepository = contactEventRepository
        self.sessionDelegate = ContactEventsUploaderSessionDelegate(validator: trustValidator)
        self.session = makeSession(ContactEventsUploader.backgroundIdentifier, sessionDelegate)

        sessionDelegate.contactEventsUploader = self
    }

    func upload(from startDate: Date, with symptoms: Symptoms) throws {
        let requested = UploadLog.Requested(startDate: startDate, symptoms: symptoms)
        persisting.uploadLog = persisting.uploadLog + [UploadLog(event: .requested(requested))]

        guard
            let registration = persisting.registration
            else { return }

        try upload(requested, with: registration)
    }

    func cleanup() {
        let lastDate = persisting.uploadLog
            .compactMap { log in
                guard case .started(let date) = log.event else { return nil }
                return date
            }
            .max() ?? Date() // conservatively default to removing everything if we somehow don't have a started log

        contactEventRepository.remove(through: lastDate)

        persisting.uploadLog = persisting.uploadLog + [UploadLog(event: .completed(error: nil))]
    }

    func error(_ error: Swift.Error) {
        persisting.uploadLog = persisting.uploadLog + [UploadLog(event: .completed(error: error.localizedDescription))]
    }

    // Keeping it simple - we try and reupload contact events if we need to upload,
    // aren't currently uploading, and it's been an hour since the last attempt.
    func ensureUploading() throws {
        guard
            let registration = persisting.registration,
            let lastUploadLog = persisting.uploadLog.last
        else { return }

        let needsUpload: Bool
        switch lastUploadLog.event {
        case .requested:
            needsUpload = true
        case .started:
            needsUpload = false
        case .completed(let error):
            needsUpload = error != nil
        }

        let oneHour: TimeInterval = 60 * 60
        let hasBeenAnHour = (Date().timeIntervalSince(lastUploadLog.date)) > oneHour
        guard needsUpload && hasBeenAnHour else { return }

        guard
            let requested = persisting.uploadLog.compactMap({ log -> UploadLog.Requested? in
                guard case .requested(let requested) = log.event else {
                    return nil
                }

                return requested
            }).last
        else {
            cleanup()
            return
        }

        try? upload(requested, with: registration)
    }

    //MARK: - Private

    private func upload(_ requested: UploadLog.Requested, with registration: Registration) throws {
        let contactEvents = contactEventRepository.contactEvents
        let lastDate = contactEvents.map { $0.timestamp }.max() ?? Date() // conservatively default to the current time
        persisting.uploadLog = persisting.uploadLog + [
            UploadLog(event: .started(lastContactEventDate: lastDate))
        ]

        let request = UploadProximityEventsRequest(
            registration: registration,
            symptoms: requested.symptoms,
            symptomsTimestamp: requested.startDate,
            contactEvents: contactEvents
        )

        try session.upload(with: request)
    }
}

// We need to pass the URLSession delegate when we create the URLSession, so this
// creates a catch-22 that we resolve by having this separate delegate object be
// initialized first.
class ContactEventsUploaderSessionDelegate: TrustValidatingURLSessionDelegate, URLSessionTaskDelegate {

    let logger = Logger(label: "ContactEventsUploaderSessionDelegate")

    fileprivate var contactEventsUploader: ContactEventsUploader!
    var completionHandler: (() -> Void)?

//    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//        print(#file, #function, task, "bytesSent: \(bytesSent), totalBytesSent: \(totalBytesSent), totalBytesExpectedToSend: \(totalBytesExpectedToSend)")
//    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            contactEventsUploader.error(error)
            return
        }

        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode else {
            // If we ever get here, things have gone quite wrong, so just clean and bail.
            contactEventsUploader.cleanup()
            return
        }

        switch statusCode {
        case 429:
            contactEventsUploader.error(ContactEventsUploader.Error.server)
        case 500..<600:
            contactEventsUploader.error(ContactEventsUploader.Error.server)
        default:
            contactEventsUploader.cleanup()
        }

        print(#file, #function, task)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background

        DispatchQueue.main.async {
            self.completionHandler?()
        }
    }

}
