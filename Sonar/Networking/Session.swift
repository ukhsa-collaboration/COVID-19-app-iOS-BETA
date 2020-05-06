//
//  HTTPService.swift
//  Sonar
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum HTTPMethod: Equatable {
    case get
    case post(data: Data)
    case patch(data: Data)
    case put(data: Data?)
}

enum Urlable: Equatable {
    case path(String)
    case url(URL)
}

protocol Request {
    
    associatedtype ResponseType
    
    var method: HTTPMethod { get }
    var urlable: Urlable { get }
    var headers: [String: String] { get }
    
    func parse(_ data: Data) throws -> ResponseType
    
    var sonarHeaderValue: String { get }
}

extension Request {

    var baseURL: URL { URL(string: Environment.apiEndpoint)! }
    var sonarHeaderValue: String { Environment.sonarHeaderValue }

    func urlRequest() -> URLRequest {
        let url: URL
        switch urlable {
        case .path(let p):
            url = URL(string: p, relativeTo: baseURL)!
        case .url(let u):
            url = u
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.allHTTPHeaderFields = headers
        urlRequest.setValue(sonarHeaderValue, forHTTPHeaderField: "X-Sonar-Foundation")

        switch method {
        case .get:
            urlRequest.httpMethod = "GET"

        case .post(let data):
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data

        case .patch(let data):
            urlRequest.httpMethod = "PATCH"
            urlRequest.httpBody = data

        case .put(let data):
            urlRequest.httpMethod = "PUT"
            if let data = data {
                urlRequest.httpBody = data
            }
        }

        return urlRequest
    }

}

protocol Session {

    var delegateQueue: OperationQueue { get }
    
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void)

    func upload<R: Request>(with request: R) throws
}

extension Session {

    func execute<R: Request>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        execute(request, queue: delegateQueue, completion: completion)
    }

}
