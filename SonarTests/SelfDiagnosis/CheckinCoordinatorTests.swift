//
//  CheckinCoordinatorTests.swift
//  SonarTests
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class CheckinCoordinatorTests: XCTestCase {

    var coordinator: CheckinCoordinator!

    var navController: UINavigationController!

    override func setUp() {
        navController = SynchronousNavigationControllerDouble()
    }
    
    func testScreenSequence() throws {
        var resultingSymptoms: Symptoms?
        coordinator = make(checkin: StatusState.Checkin(symptoms: [], checkinDate: Date()), completion: { symptoms in
            resultingSymptoms = symptoms
        })

        coordinator.start()
        let tempVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(tempVc.view)
        XCTAssertEqual(tempVc.questionTitle, "TEMPERATURE_QUESTION".localized)
        
        tempVc.yesTapped()
        tempVc.buttonTapped()
        let coughVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(coughVc.view)
        XCTAssertEqual(coughVc.questionTitle, "COUGH_QUESTION".localized)

        coughVc.yesTapped()
        coughVc.buttonTapped()
        XCTAssertEqual(resultingSymptoms, Symptoms([.temperature, .cough]))
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

    private func make(
        checkin: StatusState.Checkin,
        completion: @escaping (Symptoms) -> Void = {_ in }
    ) -> CheckinCoordinator {
        return CheckinCoordinator(
            navigationController: navController,
            checkin: checkin,
            completion: completion
        )
    }

}
