//
//  AcknowledgmentRequest.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class AcknowledgmentRequest: Request {

    typealias ResponseType = Void

    let method: HTTPMethod = .put(data: nil)
    let urlable: Urlable
    let headers: [String: String] = [:]

    init(url: URL) {
        urlable = .url(url)
    }

    func parse(_ data: Data) throws -> Void {
    }

}
