//
//  LinkingIdManager.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LinkingIdManaging {
    func fetchLinkingId(completion: @escaping (LinkingId?, String?) -> Void)
}

enum LinkingIdResult {
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

    func fetchLinkingId(completion: @escaping (LinkingId?, String?) -> Void) {
        guard let registration = persisting.registration else {
            completion(nil, "Please wait until your setup has completed to see the app reference code.")
            return
        }

        let request = LinkingIdRequest(registration: registration)
        session.execute(request) { result in
            switch result {
            case .success(let linkingId):
                completion(linkingId, nil)
            case .failure:
                completion(nil, "Please connect your phone to the internet to see the app reference code.")
            }
        }
    }
}
