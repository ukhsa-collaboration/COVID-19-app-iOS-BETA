//
//  BluetoothPayloadTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class BroadcastPayloadTests: XCTestCase {

    let txDate: Date = Date(timeIntervalSince1970: 1588253464)
    
    var cryptogram: Data!
    var payload: BroadcastPayload!
    
    override func setUp() {
        cryptogram = Data(count: ConcreteBroadcastIdEncrypter.broadcastIdLength)
        payload = BroadcastPayload(cryptogram: cryptogram, hmacKey: SecKey.sampleHMACKey)
    }
    
    // Verify the hmac is correct from the command line:
    // MESSAGE="AzoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAF6q0xg="
    // KEY="LWbqBBxfV5vob3ApsPhgOI8aiFcKYP8jLQ2fKb8Y1C0="
    // echo "$MESSAGE" | base64 --decode | openssl dgst -hmac "$(echo "$KEY" | base64 --decode)" -sha256 -binary | head -c 16 | base64

    
    func testBroadcastPayload() throws {
        let data = payload.data(txDate: txDate)
        print(" country code is \(data.subdata(in: 0..<2).base64EncodedString())")
        print("   cryptogram is \(data.subdata(in: 2..<108).base64EncodedString())")
        print("      txPower is \(data.subdata(in: 108..<109).base64EncodedString())")
        print("       txDate is \(data.subdata(in: 109..<113).base64EncodedString())")
        print("whole payload is \(data.subdata(in: 0..<113).base64EncodedString())")
        print("         hmac is \(data.subdata(in: 113..<129).base64EncodedString())")
        
        XCTAssertEqual(data.subdata(in: 0..<2), BroadcastPayload.ukISO3166CountryCode.data)
        XCTAssertEqual(data.subdata(in: 2..<108), cryptogram)
        XCTAssertEqual(data.subdata(in: 108..<109), Int8(0).data)
        XCTAssertEqual(data.subdata(in: 109..<113), Int32(txDate.timeIntervalSince1970).data)
        XCTAssertEqual(data.subdata(in: 113..<129), Data(base64Encoded: "/PLmLUXPduKo9659AJqEJQ=="))
    }
    
    func testIncomingBroadcastPayload() {
        let broadcastPayload = IncomingBroadcastPayload(data: payload.data(txDate: txDate))
        
        XCTAssertEqual(broadcastPayload.countryCode, BroadcastPayload.ukISO3166CountryCode)
        XCTAssertEqual(broadcastPayload.cryptogram, cryptogram)
        XCTAssertEqual(broadcastPayload.txPower, 0)
        XCTAssertEqual(broadcastPayload.transmissionTime, Int32(txDate.timeIntervalSince1970))
        XCTAssertEqual(broadcastPayload.hmac, Data(base64Encoded: "/PLmLUXPduKo9659AJqEJQ=="))
    }

}
