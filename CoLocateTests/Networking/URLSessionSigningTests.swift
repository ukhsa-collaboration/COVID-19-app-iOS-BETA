//
//  URLSessionSigningTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//
//
//  PatchContactIdentifierRequest.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class URLSessionSigningTests: XCTestCase {

    let deviceId = UUID()
    let deviceId1 = UUID()
    let deviceId2 = UUID()
    let deviceId3 = UUID()
    
    var request: PatchContactEventsRequest!
    
    var urlRequest: URLRequest!
    
    var urlResponse: HTTPURLResponse!
    var responseData: String!
    var responseDataAsData: Data!
    var expectedHmac = "30b83b81eb8d45a95b3a98d728ade5befb5d3b5b7746f8dd246112c5ab27b091"
    var computedHmac: String!
    // from https://www.freeformatter.com/hmac-generator.html
    var baseTS: TimeInterval!
    var withinTS: TimeInterval!
    var outsideTS: TimeInterval!
    
    override func setUp() {
        let contactEvents = [
            ContactEvent(uuid: deviceId1),
            ContactEvent(uuid: deviceId2),
            ContactEvent(uuid: deviceId3)
        ]
        
        print("CREATING REQUEST")
        request = PatchContactEventsRequest(deviceId: deviceId, contactEvents: contactEvents)
        
        urlRequest = URLSession.shared.createRequest(request)
        
        baseTS = 0.0
        let dateTimeString = URLSession.formatter.string(from: Date(timeIntervalSince1970: baseTS))
        withinTS = baseTS + 59.0
        outsideTS = baseTS + 61.0
        
        responseData = "{\"field\": \"value\"}"
        responseDataAsData = responseData.data(using: .utf8)
        computedHmac = URLSession.shared.hmacSha256(dateTimeString:dateTimeString,body: responseDataAsData)
        print("Epoch date time: \(dateTimeString)")
        print("Computed HMAC: \(computedHmac)")
        print("Expected HMAC: \(expectedHmac)")
        
        urlResponse = HTTPURLResponse(url: URL(string:"https://data-service.cp.somewhere/api/residents/" + deviceId.uuidString)!, statusCode: 200, httpVersion: "1.0", headerFields: [
            SonarHeaders.Signature: expectedHmac,
            SonarHeaders.Timestamp: dateTimeString
        ])
        
    }

    func testHasHMAC() {
        let hmac = urlRequest.allHTTPHeaderFields![SonarHeaders.Signature]
        print("HMAC: \(String(describing: hmac))")
        XCTAssertNotNil(hmac)
    }
    
    func testHasTimestamo() {
        XCTAssertNotNil(urlRequest.allHTTPHeaderFields![SonarHeaders.Timestamp])
    }
    
    func testDataNotModified() {
        XCTAssertEqual(urlRequest.httpBody!,request.data)
    }
    
    func testSignatureValid() {
        XCTAssertNoThrow(try URLSession.shared.checkResponseSignature(data: responseDataAsData,response: urlResponse, now: baseTS))
    }
    
}
