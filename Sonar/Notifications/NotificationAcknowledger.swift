//
//  NotificationAcknowledger.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class NotificationAcknowledger {

    let persisting: Persisting
    let session: Session

    init(persisting: Persisting, session: Session) {
        self.persisting = persisting
        self.session = session
    }

    // Returns if we have already ack'ed the notification
    func ack(userInfo: [AnyHashable: Any]) -> Bool {
        guard
            let ackString = userInfo["acknowledgmentUrl"] as? String,
            let ackUrl = URL(string: ackString)
        else {
            // No ackUrl means there's nothing to ack
            return false
        }

        // Always send the ack
        let request = AcknowledgmentRequest(url: ackUrl)
        session.execute(request) { _ in
            // fire and forget - we don't care about the result of this call
        }

        if persisting.acknowledgmentUrls.contains(ackUrl) {
            return true
        } else {
            persisting.acknowledgmentUrls = persisting.acknowledgmentUrls.union([ackUrl])
            return false
        }
    }

}
