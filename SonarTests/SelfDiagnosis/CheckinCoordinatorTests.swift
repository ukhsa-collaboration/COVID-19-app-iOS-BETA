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
    
    var coordinator: QuestionnaireCoordinator!
    
    var navController: UINavigationController!
    
    override func setUp() {
        navController = SynchronousNavigationControllerDouble()
    }
    
    func testScreenSequence() throws {
        var resultingSymptoms: Symptoms?
        coordinator = make(symptoms: [], completion: { symptoms in
            resultingSymptoms = symptoms
        })
        
        coordinator.start()
        let tempVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(tempVc.view)
        XCTAssertEqual(tempVc.questionTitle, "TEMPERATURE_QUESTION".localized)
        tempVc.yesTapped()
        tempVc.continueTapped()
        
        let coughVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(coughVc.view)
        XCTAssertEqual(coughVc.questionTitle, "COUGH_QUESTION".localized)
        coughVc.yesTapped()
        coughVc.continueTapped()
        
        let anosmiaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(anosmiaVc.view)
        XCTAssertEqual(anosmiaVc.questionTitle, "ANOSMIA_QUESTION".localized)
        anosmiaVc.yesTapped()
        anosmiaVc.continueTapped()
        
        let sneezeVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(sneezeVc.view)
        XCTAssertEqual(sneezeVc.questionTitle, "SNEEZE_QUESTION".localized)
        sneezeVc.yesTapped()
        sneezeVc.continueTapped()
        
        let nauseaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(nauseaVc.view)
        XCTAssertEqual(nauseaVc.questionTitle, "NAUSEA_QUESTION".localized)
        nauseaVc.yesTapped()
        nauseaVc.continueTapped()
        
        XCTAssertEqual(resultingSymptoms, Symptoms([.temperature, .cough, .anosmia, .sneeze, .nausea]))
    }
    
    func testNoTemperatureQuestion() throws {
        coordinator = make(symptoms: [.cough])
        
        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        
        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_QUESTION".localized)
    }
    
    func testExistingTemperatureQuestion() throws {
        coordinator = make(symptoms: [.temperature])
        
        coordinator.start()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        
        XCTAssertEqual(vc.questionTitle, "TEMPERATURE_CHECKIN_QUESTION".localized)
    }
    
    func testNoCoughQuestion() throws {
        coordinator = make(symptoms: [.temperature])
        
        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        
        XCTAssertEqual(vc.questionTitle, "COUGH_QUESTION".localized)
    }
    
    func testExistingCoughQuestion() throws {
        coordinator = make(symptoms: [.cough])
        
        coordinator.openCoughView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        
        XCTAssertEqual(vc.questionTitle, "COUGH_CHECKIN_QUESTION".localized)
    }
    
    func testAnosmiaQuestion() throws {
        coordinator = make(symptoms: [])
        
        coordinator.openAnosmiaView()
        let vc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        
        XCTAssertEqual(vc.questionTitle, "ANOSMIA_QUESTION".localized)
    }
    
    private func make(symptoms: Symptoms?, completion: @escaping (Symptoms) -> Void = {_ in }) -> QuestionnaireCoordinator {
        let symptomatic = StatusState.Symptomatic(symptoms: symptoms, startDate: Date(), checkinDate: Date())
        return QuestionnaireCoordinator(navigationController: navController,
                                        statusStateMachine: StatusStateMachiningDouble(state: .symptomatic(symptomatic)),
                                        questionnaireType: .checkin,
                                        completion: completion
        )
    }
    
}
