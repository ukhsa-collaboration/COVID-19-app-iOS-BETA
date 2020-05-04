//
//  UpdateDiagnosisCoordinatorTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class UpdateDiagnosisCoordinatorTests: XCTestCase {

    var coordinator: UpdateDiagnosisCoordinator!

    var navController: UINavigationController!
    var persisting: PersistenceDouble!
    var statusViewController: StatusViewController!

    override func setUp() {
        navController = UINavigationController()
        persisting = PersistenceDouble()
        statusViewController = StatusViewController()

        coordinator = UpdateDiagnosisCoordinator(
            navigationController: navController,
            persisting: persisting,
            statusViewController: statusViewController
        )
    }

    func testNoTemperatureQuestion() throws {
        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_QUESTION".localized)
    }

    func testExistingTemperatureQuestion() throws {
        persisting.selfDiagnosis = SelfDiagnosis(type: .subsequent, symptoms: [.temperature], startDate: Date())

        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_CHECKIN_QUESTION".localized)
    }

    func testNoCoughQuestion() throws {
        persisting.selfDiagnosis = SelfDiagnosis(type: .subsequent, symptoms: [.temperature], startDate: Date())

        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "COUGH_QUESTION".localized)
    }

    func testExistingCoughQuestion() throws {
        persisting.selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: [.cough], startDate: Date())

        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "COUGH_CHECKIN_QUESTION".localized)
    }

}
