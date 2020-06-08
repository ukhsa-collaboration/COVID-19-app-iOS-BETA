//
//  URLSession.swift
//  Sonar
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

extension URLSessionConfiguration {
    func secure() {
        if #available(iOS 13.0, *) {
            tlsMinimumSupportedProtocolVersion = .TLSv12
        }
        tlsMinimumSupportedProtocol = .tlsProtocol12
        httpCookieAcceptPolicy = .never
        httpShouldSetCookies = false
        httpCookieStorage = nil
        urlCache = nil
    }
}

extension URLSession {
    
    convenience init(trustValidator: TrustValidating) {
        // Use of `ephemeral` here is a precaution. We are disabling all caching manually anyway, but using this instead
        // of `default` means if we miss something (especially as new properties are added over time) we’ll inherit the
        // `ephemeral` value instead of the `default` one.
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.secure()
        
        let delegate = TrustValidatingURLSessionDelegate(validator: trustValidator)
        self.init(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}

extension URLSession: Session {

    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        let completion = { result in queue.addOperation { completion(result) } }

        let urlRequest = request.urlRequest()

        let task = dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                // force-unwrap because Swift's flow-typing isn't smart enough to recognize the == nil
                completion(.failure(error!))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                assertionFailure("Expected an HTTPURLResponse, got \(String(describing: response))")
                return
            }

            let statusCode = httpResponse.statusCode
            guard 200..<300 ~= statusCode else {
                logger.error("Request to \(urlRequest.url?.path ?? "(unknown)") received \(statusCode). Response body: \(data.flatMap { String(bytes: $0, encoding: .utf8) } ?? "<empty>")")
                let userInfo = [NSLocalizedDescriptionKey: "Sorry, your request at this time could not be completed. Please try again later."]
                let error = NSError(domain: "RequestErrorDomain", code: statusCode, userInfo: userInfo)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                assertionFailure("data shouldn't be nil if the error is nil")
                return
            }
            completion(Result { try request.parse(data) })
        }

        task.resume()
    }

    func upload<R: Request>(with request: R) throws {
        let urlRequest = request.urlRequest()

        // According to the Apple docs, the upload task copies the file into its own temporary
        // location to stream data from, so it should be safe to use the tmpdir for this.
        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("contactEvents.json")
        try urlRequest.httpBody!.write(to: fileURL)

        let task = uploadTask(with: urlRequest, fromFile: fileURL)
        task.resume()

        try? FileManager.default.removeItem(at: fileURL)
    }

}

private let logger = Logger(label: "URLSession")
