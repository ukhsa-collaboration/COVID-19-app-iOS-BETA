//
//  LinkingIdRequest.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

typealias LinkingId = String

class LinkingIdRequest: SecureRequest, Request {
    typealias ResponseType = LinkingId

    let method: HTTPMethod
    let urlable: Urlable

    let decoder = JSONDecoder()

    init(registration: Registration) {
        urlable = .path("/api/residents/\(registration.id.uuidString)/linking-id")

        let bodyData = "{}".data(using: .utf8)!
        method = .put(data: bodyData)

        super.init(registration.secretKey, bodyData, [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ])
    }

    func parse(_ data: Data) throws -> LinkingId {
        let response = try decoder.decode(LinkingIdResponse.self, from: data)
        return response.linkingId
    }

}

fileprivate struct LinkingIdResponse: Codable {
    let linkingId: LinkingId
}
