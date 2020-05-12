//
//  StatusContent.swift
//  Sonar
//
//  Created by NHSX on 4/30/20.
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

    subscript(statusState: StatusState) -> StatusLinks {
        get {
            switch statusState {
            case .ok: return blue
            case .symptomatic, .checkin: return amber
            case .exposed: return red
            }
        }
    }

}

struct StatusLinks: Decodable {

    let readUrl: URL
    let nhsCoronavirusUrl: URL

}
