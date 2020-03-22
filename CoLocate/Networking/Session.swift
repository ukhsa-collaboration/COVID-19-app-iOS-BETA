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

struct SonarHeaders {
    static let Signature = "Sonar-Message-Signature"
    static let Timestamp = "Sonar-Message-Timestamp"
}

protocol Request {
    
    associatedtype ResponseType
    
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String]? { get set }
    var signed: Bool { get }
    var data: Data { get } // required for signing
    
    func parse(_ data: Data) throws -> ResponseType
}

enum RequestErrors: Error {
    case timestampTooOld
    case invalidSignature
    case missingSignature
    case missingTimestamp
}

protocol Session {
    
    func execute<R: Request>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void)
    
}
