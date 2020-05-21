//
//  ContentURLs.swift
//  Sonar
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContentURLs {
    static let shared: ContentURLs = {
        let path = Bundle.main.url(forResource: "URLs", withExtension: "plist")!
        let raw = try! Data(contentsOf: path)
        return try! PropertyListDecoder().decode(ContentURLs.self, from: raw)
    }()

    let info: URL
    let moreAbout: URL
    let privacyAndData: URL
    let ourPolicies: URL
    let nhs111Coronavirus: URL
    let statusInfo: URL
    let workplaceGuidance: URL
    let regionalServices: URL
    private let status: StatusesURLs
    private let applyForTestBase: URL

    func currentAdvice(for statusState: StatusState) -> URL {
        currentStatusURLs(for: statusState).currentAdvice
    }
    
    func applyForTest(referenceCode: String?) -> URL {
        guard let referenceCode = referenceCode else { return applyForTestBase }
        var components = URLComponents(url: applyForTestBase, resolvingAgainstBaseURL: false)!
        components.queryItems?.append(URLQueryItem(name: "refcode", value: referenceCode))
        return components.url!
    }

    private func currentStatusURLs(for statusState: StatusState) -> StatusURLs {
        switch statusState {
        case .ok, .unexposed: return status.ok
        case .symptomatic, .checkin: return status.symptomatic
        case .exposed: return status.exposed
        }
    }
}

extension ContentURLs: Decodable {
    enum CodingKeys: CodingKey {
        case info
        case moreAbout
        case privacyAndData
        case ourPolicies
        case nhs111Coronavirus
        case applyForTest
        case statusInfo
        case workplaceGuidance
        case regionalServices
        case status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        info = try values.decodeURL(forKey: .info)
        moreAbout = try values.decodeURL(forKey: .moreAbout)
        privacyAndData = try values.decodeURL(forKey: .privacyAndData)
        ourPolicies = try values.decodeURL(forKey: .ourPolicies)
        nhs111Coronavirus = try values.decodeURL(forKey: .nhs111Coronavirus)
        applyForTestBase = try values.decodeURL(forKey: .applyForTest)
        statusInfo = try values.decodeURL(forKey: .statusInfo)
        workplaceGuidance = try values.decodeURL(forKey: .workplaceGuidance)
        regionalServices = try values.decodeURL(forKey: .regionalServices)

        status = try values.decode(StatusesURLs.self, forKey: .status)
    }
}

struct StatusesURLs: Decodable {
    let ok: StatusURLs
    let exposed: StatusURLs
    let symptomatic: StatusURLs
}

struct StatusURLs: Decodable {
    let currentAdvice: URL

    enum CodingKeys: CodingKey {
        case currentAdvice
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        currentAdvice = try values.decodeURL(forKey: .currentAdvice)
    }
}

fileprivate extension KeyedDecodingContainer {
    func decodeURL(forKey key: Key) throws -> URL {
        return URL(string: try decode(String.self, forKey: key))!
    }
}