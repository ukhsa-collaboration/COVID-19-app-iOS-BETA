//
//  ColorTest.swift
//  SonarTests
//
//  Created by NHSX on 03/06/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ColorTest: XCTestCase {
    func testColorsExistInBundle() throws {
        let _ = try XCTUnwrap(UIColor.nhs.grey.one)
        let _ = try XCTUnwrap(UIColor.nhs.grey.two)
        let _ = try XCTUnwrap(UIColor.nhs.grey.three)
        let _ = try XCTUnwrap(UIColor.nhs.grey.four)
        let _ = try XCTUnwrap(UIColor.nhs.grey.five)

        let _ = try XCTUnwrap(UIColor.nhs.error)
        let _ = try XCTUnwrap(UIColor.nhs.button)
        let _ = try XCTUnwrap(UIColor.nhs.errorBackground)
        let _ = try XCTUnwrap(UIColor.nhs.text)
        let _ = try XCTUnwrap(UIColor.nhs.secondaryText)
        let _ = try XCTUnwrap(UIColor.nhs.blue)
        let _ = try XCTUnwrap(UIColor.nhs.link)
        let _ = try XCTUnwrap(UIColor.nhs.darkBlue)
        let _ = try XCTUnwrap(UIColor.nhs.white)
        let _ = try XCTUnwrap(UIColor.nhs.highlight)
        let _ = try XCTUnwrap(UIColor.nhs.errorGrey)
        let _ = try XCTUnwrap(UIColor.nhs.warmYellow)
    }
}
