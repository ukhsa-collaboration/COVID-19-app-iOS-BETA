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

protocol Session {

    var delegateQueue: OperationQueue { get }
    
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void)
    
}

extension Session {

    func execute<R: Request>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        execute(request, queue: delegateQueue, completion: completion)
    }

}
