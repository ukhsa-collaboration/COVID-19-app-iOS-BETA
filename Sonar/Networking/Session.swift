//
//  HTTPService.swift
//  Sonar
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum HTTPMethod: Equatable {
    var body: Data? {
        switch self {
        case .get: return nil
        case .post(let data), .patch(let data): return data
        case .put(let data): return data
        }
    }
    
    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .patch: return "PATCH"
        }
    }
    
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
    
    var url: URL {
        switch urlable {
        case .path(let p):
            return URL(string: p, relativeTo: baseURL)!
        case .url(let u):
            return u
        }
    }

    func urlRequest() -> URLRequest {
        var urlRequest = URLRequest(url: url)

        urlRequest.allHTTPHeaderFields = headers
        urlRequest.setValue(sonarHeaderValue, forHTTPHeaderField: "X-Sonar-Foundation")
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            urlRequest.setValue(build, forHTTPHeaderField: "X-Sonar-App-Version")
        }

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

    #if DEBUG
    // Note: NSString is load-bearing here. Using it instead of String prevents lldb from
    // backslash-escaping single quotes in a way that changes the meaning of the command.
    func toCurlCommand() -> NSString {
        func escapeSingleQuotes(_ s: String) -> String {
            return s.replacingOccurrences(of: "'", with: "\\'")
        }
        
        let actualRequest = urlRequest()
        let headerArgs = actualRequest.allHTTPHeaderFields!.map { kv in
            let (k, v) = kv
            return "--header '\(escapeSingleQuotes(k)): \(escapeSingleQuotes(v))'"
        }.joined(separator: " ")
        
        let bodyArgs: String
        switch method {
        case .get:
            bodyArgs = ""
        default:
            bodyArgs = "--data '\(escapeSingleQuotes(String(data: method.body!, encoding: .utf8)!))'"
        }

        
        return NSString(string: "curl -v \(headerArgs) --request \(method.name) \(bodyArgs) \(actualRequest.url!.absoluteString)")
    }
    #endif
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
