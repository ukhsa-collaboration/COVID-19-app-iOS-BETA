//
//  URLSessionDelegate.swift
//  Sonar
//
//  Created by NHSX on 22/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class TrustValidatingURLSessionDelegate: NSObject, URLSessionDelegate {
    
    private let validator: TrustValidating
    
    init(validator: TrustValidating) {
        self.validator = validator
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if validator.canAccept(challenge.protectionSpace.serverTrust) {
            completionHandler(.performDefaultHandling, nil)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
