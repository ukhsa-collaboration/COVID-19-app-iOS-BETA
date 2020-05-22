//
//  PactMockServiceHelper.swift
//  SonarPactTests
//
//  Created by NHSX on 22/5/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import PactConsumerSwift

class PactMockServiceHelper {
    static let SchemeAndHost = "https://localhost"
    static let Port = 1234
    static let Endpoint =  "\(SchemeAndHost):\(Port)"
    
    static func createVerificationService() -> PactVerificationService {
        return PactVerificationService(
            url: SchemeAndHost,
            port: Port
        )
    }
    
    static func clearSession() {
        var request = URLRequest(url: URL(string: "\(Endpoint)/session")!)
        request.httpMethod = "DELETE"
        request.addValue("true", forHTTPHeaderField: "X-Pact-Mock-Service")
        let urlSession = URLSession(configuration: .default)
        let task = urlSession.dataTask(with: request)
        task.resume()
    }
}
