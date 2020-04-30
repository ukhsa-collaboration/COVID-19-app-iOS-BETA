//
//  StatusContent.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

struct StatusContent: Decodable {

    static let shared: StatusContent = {
        let filePath = Bundle.main.url(forResource: "statusContent", withExtension: "json")!
        let data = try! Data(contentsOf: filePath)

        let decoder = JSONDecoder()
        return try! decoder.decode(StatusContent.self, from: data)
    }()

    let blue: StatusLinks
    let amber: StatusLinks
    let red: StatusLinks

    subscript(status: Status) -> StatusLinks {
        get {
            switch status {
            case .blue: return blue
            case .amber: return amber
            case .red: return red
            }
        }
    }

}

struct StatusLinks: Decodable {

    let readUrl: URL
    let nhsCoronavirusUrl: URL

}
