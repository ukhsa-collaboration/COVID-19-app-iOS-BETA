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

    struct Body: Codable {
        let sonarId: UUID
    }

    let method: HTTPMethod
    let urlable = Urlable.path("/api/app-instances/linking-id")

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(registration: Registration) {
        let body = Body(sonarId: registration.sonarId)
        let data = try! encoder.encode(body)
        method = .put(data: data)

        super.init(registration.secretKey, data, [
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
