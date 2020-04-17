//
//  ContactEventExpiryHandler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ContactEventExpiryHandler {
    private let contactEventRepository: ContactEventRepository
    
    init(notificationCenter: NotificationCenter, contactEventRepository: ContactEventRepository) {
        self.contactEventRepository = contactEventRepository
        notificationCenter.addObserver(self, selector: #selector(significantTimeDidChange), name: UIApplication.significantTimeChangeNotification, object: nil)
    }
    
    @objc private func significantTimeDidChange() {
        contactEventRepository.removeExpiredContactEvents()
    }
}
