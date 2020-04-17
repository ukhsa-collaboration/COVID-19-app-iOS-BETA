//
//  ProjectTests.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class ProjectTests: XCTestCase {
    
    func testWeHaveALaunchStoryboard() {
        let info = Bundle.app.infoDictionary
        
        XCTAssertNotNil(info?["UILaunchStoryboardName"])
    }
    
    func testThereAreNoOverridesForATS() {
        let info = Bundle.app.infoDictionary
        
        XCTAssertNil(info?["NSAppTransportSecurity"], "There should be no overrides for App Transport Security.")
    }
    
    func testGoogleAnalyticsIDFVCollectionIsDisabled() throws {
        let info = Bundle.app.infoDictionary
        
        let isEnabeld = try XCTUnwrap(info?["GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED"] as? Bool, "This key should be set explicitely")
        XCTAssertFalse(isEnabeld)
    }
    
    #if targetEnvironment(simulator)
    func testThatProjectFileHasNoEmbeddedBuildConfigurations() {
        guard let projectFilePath = Bundle(for: ProjectTests.self).infoDictionary?["projectFilePath"] as? String else {
            XCTFail("The project file path should be specified in the info.plist file.")
            return
        }
        
        let url = URL(fileURLWithPath: "\(projectFilePath)/project.pbxproj")
        
        guard let project = try? String(contentsOf: url) else {
            XCTFail("Failed to read project file. Maybe path is incorrect or we don’t have permission.")
            return
        }
        
        if let range = project.range(of: "buildSettings\\s*=\\s*\\{[^\\}]*?=[^\\}]*?\\}", options: .regularExpression) {
            let buildSettings = project[range]
                .replacingOccurrences(of: "\n", with: " ")
            XCTFail("There should be no build settings in the project file. Please move all settings to .xcconfig files. Found: \(buildSettings)")
        }
    }
    #endif
    
}

private extension Bundle {
    
    // An alias to indicate that we should running as part of the main app in order for these tests to function
    // properly.
    // Some tests failing (like `testWeHaveAStoryboard`) helps detect if we’ve moved this class to, say, a framework
    // or swift pacakge tests.
    static var app: Bundle { Bundle.main }
    
}
