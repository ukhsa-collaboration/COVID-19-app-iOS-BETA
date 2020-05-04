//
//  LinkingIdManager.swift
//  Sonar
//
//  Created by NHSX.
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
        notificationCenter: NotificationCenter,
        persisting: Persisting,
        session: Session
    ) {
        self.persisting = persisting
        self.session = session

        notificationCenter.addObserver(
            forName: RegistrationCompletedNotification,
            object: nil,
            queue: nil
        ) { _ in
            self.fetchLinkingId { _ in }
        }
    }

    func fetchLinkingId(completion: @escaping (LinkingId?) -> Void) {
        if let linkingId = persisting.linkingId {
            completion(linkingId)
            return
        }

        guard let registration = persisting.registration else {
            completion(nil)
            return
        }

        let request = LinkingIdRequest(registration: registration)
        session.execute(request) { result in
            switch result {
            case .success(let linkingId):
                self.persisting.linkingId = linkingId
                completion(linkingId)
            case .failure:
                completion(nil)
            }
        }
    }
}
