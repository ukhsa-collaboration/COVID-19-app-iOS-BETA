//
//  LinkingIdManager.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LinkingIdManaging {
    func fetchLinkingId(completion: @escaping (LinkingIdResult) -> Void)
}

enum LinkingIdResult: Equatable {
    case success(String)
    case error(String)
}

class LinkingIdManager: LinkingIdManaging {
    let persisting: Persisting
    let session: Session

    init(
        persisting: Persisting,
        session: Session
    ) {
        self.persisting = persisting
        self.session = session
    }

    func fetchLinkingId(completion: @escaping (LinkingIdResult) -> Void) {
        guard let registration = persisting.registration else {
            completion(.error("Please wait until your setup has completed to see the app reference code."))
            return
        }

        let request = LinkingIdRequest(registration: registration)
        session.execute(request) { result in
            switch result {
            case .success(let linkingId):
                completion(.success(linkingId))
            case .failure:
                completion(.error("Please connect your phone to the internet to see the app reference code."))
            }
        }
    }
}
