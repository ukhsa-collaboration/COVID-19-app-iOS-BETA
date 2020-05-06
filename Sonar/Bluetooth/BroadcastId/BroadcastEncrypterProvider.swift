//
//  BroadcastEncrypterProvider.swift
//  Sonar
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol BroadcastIdEncrypterProvider {
    func getEncrypter() -> BroadcastIdEncrypter?
}

struct ConcreteBroadcastIdEncrypterProvider: BroadcastIdEncrypterProvider {
    
    let persistence: Persisting

    func getEncrypter() -> BroadcastIdEncrypter? {
        guard let key = persistence.registration?.broadcastRotationKey, let sonarId = persistence.registration?.id else {
            return nil
        }
        return ConcreteBroadcastIdEncrypter(key: key, sonarId: sonarId)
    }
    
}
