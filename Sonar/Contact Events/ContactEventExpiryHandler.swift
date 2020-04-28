//
//  ContactEventExpiryHandler.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ContactEventExpiryHandler {
    private let contactEventRepository: ContactEventRepository
    private let notificationCenter: NotificationCenter
    
    init(notificationCenter: NotificationCenter, contactEventRepository: ContactEventRepository) {
        self.contactEventRepository = contactEventRepository
        self.notificationCenter = notificationCenter

        notificationCenter.addObserver(self, selector: #selector(significantTimeDidChange), name: UIApplication.significantTimeChangeNotification, object: nil)
        significantTimeDidChange()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc private func significantTimeDidChange() {
        let ttl = convertDaysIntoSeconds(days: 28)
        contactEventRepository.removeExpiredContactEvents(ttl: ttl)
    }
    
    func convertDaysIntoSeconds(days: Double) -> Double {
        return days * 24 * 60 * 60
    }
}
