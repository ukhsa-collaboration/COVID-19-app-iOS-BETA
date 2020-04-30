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
    
    // Verify the hmac is correct from the command line:
    // MESSAGE="OgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABjTql4="
    // KEY="BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="
    // echo "$MESSAGE" | base64 --decode | openssl dgst -hmac "$(echo "$KEY" | base64 --decode)" -sha256 -binary | head -c 16 | base64

    
    func testBroadcastPayload() throws {
        let cryptogram = Data(count: ConcreteBroadcastIdEncrypter.broadcastIdLength)
        let payload = BroadcastPayload(cryptogram: cryptogram, secKey: SecKey.knownGoodECPublicKey).data(txDate: txDate)
        
//        print(" country code is \(payload.subdata(in: 0..<2).base64EncodedString())")
//        print("   cryptogram is \(payload.subdata(in: 2..<108).base64EncodedString())")
//        print("      txPower is \(payload.subdata(in: 108..<109).base64EncodedString())")
//        print("       txDate is \(payload.subdata(in: 109..<113).base64EncodedString())")
//        print("whole payload is \(payload.subdata(in: 0..<113).base64EncodedString())")
//        print("         hmac is \(payload.subdata(in: 113..<129).base64EncodedString())")
        
        XCTAssertEqual(payload.subdata(in: 0..<2), BroadcastPayload.ukISO3166CountryCode.data)
        XCTAssertEqual(payload.subdata(in: 2..<108), cryptogram)
        XCTAssertEqual(payload.subdata(in: 108..<109), Int8(0).data)
        XCTAssertEqual(payload.subdata(in: 109..<113), Int32(txDate.timeIntervalSince1970).data)
        XCTAssertEqual(payload.subdata(in: 113..<129), Data(base64Encoded: "+zpPV+ThO3uByAp/aiEwIg=="))
    }

}
