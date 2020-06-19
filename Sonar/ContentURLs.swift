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
    let testResults: URL
    private let status: StatusesURLs
    private let bookTestBase: URL

    func bookTest(referenceCode: String?) -> URL {
        guard let referenceCode = referenceCode else { return bookTestBase }
        var components = URLComponents(url: bookTestBase, resolvingAgainstBaseURL: false)!
        
        if components.queryItems == nil /* ugh why? */ {
            components.queryItems = []
        }
        
        components.queryItems?.append(URLQueryItem(name: "ctaToken", value: referenceCode))
        return components.url!
    }
}

extension ContentURLs: Decodable {
    enum CodingKeys: CodingKey {
        case info
        case moreAbout
        case privacyAndData
        case ourPolicies
        case nhs111Coronavirus
        case bookTest
        case statusInfo
        case workplaceGuidance
        case regionalServices
        case testResults
        case status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        info = try values.decodeURL(forKey: .info)
        moreAbout = try values.decodeURL(forKey: .moreAbout)
        privacyAndData = try values.decodeURL(forKey: .privacyAndData)
        ourPolicies = try values.decodeURL(forKey: .ourPolicies)
        nhs111Coronavirus = try values.decodeURL(forKey: .nhs111Coronavirus)
        bookTestBase = try values.decodeURL(forKey: .bookTest)
        statusInfo = try values.decodeURL(forKey: .statusInfo)
        workplaceGuidance = try values.decodeURL(forKey: .workplaceGuidance)
        regionalServices = try values.decodeURL(forKey: .regionalServices)
        testResults = try values.decodeURL(forKey: .testResults)
        status = try values.decode(StatusesURLs.self, forKey: .status)
    }
}

struct StatusesURLs: Decodable {
    let ok: StatusURLs
    let exposed: StatusURLs
    let symptomatic: StatusURLs
    let positive: StatusURLs
    let exposedSymptomatic: StatusURLs
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
