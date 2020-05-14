//
//  LinkingIdManager.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LinkingIdManaging {
    func fetchLinkingId(completion: @escaping (LinkingId?) -> Void)
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

    func fetchLinkingId(completion: @escaping (LinkingId?) -> Void) {
        guard let registration = persisting.registration else {
            completion(nil)
            return
        }

        let request = LinkingIdRequest(registration: registration)
        session.execute(request) { result in
            switch result {
            case .success(let linkingId):
                completion(linkingId)
            case .failure:
                completion(nil)
            }
        }
    }
}
