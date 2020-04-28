//
//  SessionDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class SessionDouble: Session {

    let delegateQueue = OperationQueue.current!

    var requestSent: Any?
    var executeCompletion: ((Any) -> Void)?

    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        requestSent = request
        executeCompletion = { result in
            guard let castedResult = result as? Result<R.ResponseType, Error> else {
                print("SessionDouble: got the wrong result type. Expected \(Result<R.ResponseType, Error>.self) but got \(type(of: result))")
                return
            }

            completion(castedResult)
        }
    }

    var uploadRequest: Any?
    func upload<R: Request>(with request: R) {
        uploadRequest = request    }

}
