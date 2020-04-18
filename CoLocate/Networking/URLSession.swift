//
//  URLSession.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

extension URLSession {
    static func make() -> URLSession {
        // Use of `ephemeral` here is a precaution. We are disabling all caching manually anyway, but using this instead
        // of `default` means if we miss something (especially as new properties are added over time) we’ll inherit the
        // `ephemeral` value instead of the `default` one.
        let configuration = URLSessionConfiguration.ephemeral
        
        if #available(iOS 13.0, *) {
            configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        }
        configuration.tlsMinimumSupportedProtocol = .tlsProtocol12
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        
        return URLSession(configuration: configuration)
    }
}

extension URLSession: Session {

    var baseURL: URL {
        let endpoint = Bundle(for: AppDelegate.self).infoDictionary?["API_ENDPOINT"] as! String
        return URL(string: endpoint)!
    }
    
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        let completion = { result in queue.addOperation { completion(result) } }

        let url = URL(string: request.path, relativeTo: baseURL)!
        var urlRequest = URLRequest(url: url)
        
        urlRequest.allHTTPHeaderFields = request.headers
        
        switch request.method {
        case .get:
            urlRequest.httpMethod = "GET"
            
        case .post(let data):
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            
        case .patch(let data):
            urlRequest.httpMethod = "PATCH"
            urlRequest.httpBody = data
        }
        
        let task = dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            do {
                switch (data, statusCode, error) {
                case (let data?, let statusCode?, _) where 200..<300 ~= statusCode:
                    let parsed = try request.parse(data)
                    completion(.success(parsed))

                case (let data?, let statusCode?, _):
                    logger.error("Request to \(request.path) received \(statusCode). Response body: \(String(bytes: data, encoding: .utf8) ?? "<empty>")")
                    let userInfo = [NSLocalizedDescriptionKey: "Sorry, your request at this time could not be completed. Please try again later."]
                    throw NSError(domain: "RequestErrorDomain", code: statusCode, userInfo: userInfo)

                case (_, _, let error?):
                    throw error

                default:
                    break
                }
            } catch (let error) {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

private let logger = Logger(label: "URLSession")
