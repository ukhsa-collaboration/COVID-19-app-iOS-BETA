//
//  UpdateDiagnosisCoordinatorTests.swift
//  SonarTests
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class UpdateDiagnosisCoordinatorTests: XCTestCase {

    var coordinator: UpdateDiagnosisCoordinator!

    var navController: UINavigationController!
    var statusViewController: StatusViewController!

    override func setUp() {
        navController = UINavigationController()
        statusViewController = StatusViewController()
    }

    func testNoTemperatureQuestion() throws {
        coordinator = make(checkin: StatusState.Checkin(symptoms: [.cough], checkinDate: Date()))

        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_QUESTION".localized)
    }

    func testExistingTemperatureQuestion() throws {
        coordinator = make(checkin: StatusState.Checkin(symptoms: [.temperature], checkinDate: Date()))

        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_CHECKIN_QUESTION".localized)
    }

    func testNoCoughQuestion() throws {
        coordinator = make(checkin: StatusState.Checkin(symptoms: [.temperature], checkinDate: Date()))

        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "COUGH_QUESTION".localized)
    }

    func testExistingCoughQuestion() throws {
        coordinator = make(checkin: StatusState.Checkin(symptoms: [.cough], checkinDate: Date()))

        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)

        XCTAssertEqual(vc.questionTitle, "COUGH_CHECKIN_QUESTION".localized)
    }

    private func make(checkin: StatusState.Checkin) -> UpdateDiagnosisCoordinator {
        return UpdateDiagnosisCoordinator(
            navigationController: navController,
            checkin: checkin,
            statusViewController: statusViewController,
            statusStateMachine: StatusStateMachiningDouble()
        )
    }

}
