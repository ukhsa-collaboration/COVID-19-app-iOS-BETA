//
//  ProviderKnownDetails.swift
//  SonarPactTests
//
//  Created by NHSX on 22/5/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

@testable import Sonar

class ProviderKnownDetails {
    static let timestamp = "2020-12-12T12:12:12Z"
    
    static let date: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.date(from: timestamp)!
    }()
    
    static let secretKey = HMACKey(data: Data(base64Encoded: "OuO0LzMf+b7Cw4IYAFRH+5QLCUwGTTX+X9E8bRdqAD4=")!)
    
    static let userId = UUID(uuidString: "4BAE40D4-8119-4905-B9E2-5B4ED5DBBADD")!
    
    static let broadcastKey = try! BroadcastRotationKeyConverter().fromData(Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!)
}
