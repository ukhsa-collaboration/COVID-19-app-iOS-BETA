//
//  HTTPService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case get
    case post(data: Data)
    case patch(data: Data)
}

protocol Request {
    
    associatedtype ResponseType
    
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
    
    func parse(_ data: Data) throws -> ResponseType
}

extension Request {

    var baseURL: URL {
        let endpoint = Bundle.main.infoDictionary!["API_ENDPOINT"] as! String
        return URL(string: endpoint)!
    }

    func urlRequest() -> URLRequest {
        let url = URL(string: path, relativeTo: baseURL)!
        var urlRequest = URLRequest(url: url)

        urlRequest.allHTTPHeaderFields = headers

        switch method {
        case .get:
            urlRequest.httpMethod = "GET"

        case .post(let data):
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data

        case .patch(let data):
            urlRequest.httpMethod = "PATCH"
            urlRequest.httpBody = data
        }

        return urlRequest
    }

}

protocol Session {

    var delegateQueue: OperationQueue { get }
    
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void)
    
}

extension Session {

    func execute<R: Request>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        execute(request, queue: delegateQueue, completion: completion)
    }

}
