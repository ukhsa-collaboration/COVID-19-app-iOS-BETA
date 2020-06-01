//
//  CheckinCoordinatorTests.swift
//  SonarTests
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class QuestionnaireCoordinatorTests: XCTestCase {
    
    var coordinator: QuestionnaireCoordinator!
    
    var navController: UINavigationController!
    
    override func setUp() {
        navController = SynchronousNavigationControllerDouble()
    }
    
    func testSelfDiagnosis() throws {
        var resultingSymptoms: Symptoms?
        coordinator = make(type: .selfDiagnosis, completion: { symptoms in
            resultingSymptoms = symptoms
        })
        
        coordinator.start()
        let tempVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(tempVc.view)
        XCTAssertEqual(tempVc.questionTitle, "TEMPERATURE_QUESTION".localized)
        XCTAssertEqual(tempVc.questionDetail, "TEMPERATURE_DETAIL".localized)
        XCTAssertEqual(tempVc.questionContext, "TEMPERATURE_INITIAL_CONTEXT".localized)
        XCTAssertEqual(tempVc.questionError, "TEMPERATURE_ERROR".localized)
        XCTAssertEqual(tempVc.questionYes, "TEMPERATURE_YES".localized)
        XCTAssertEqual(tempVc.questionNo, "TEMPERATURE_NO".localized)
        tempVc.yesTapped()
        tempVc.continueTapped()
        
        let coughVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(coughVc.view)
        XCTAssertEqual(coughVc.questionTitle, "COUGH_QUESTION".localized)
        XCTAssertEqual(coughVc.questionDetail, "COUGH_DETAIL".localized)
        XCTAssertEqual(coughVc.questionContext, "COUGH_INITIAL_CONTEXT".localized)
        XCTAssertEqual(coughVc.questionError, "COUGH_ERROR".localized)
        XCTAssertEqual(coughVc.questionYes, "COUGH_YES".localized)
        XCTAssertEqual(coughVc.questionNo, "COUGH_NO".localized)
        coughVc.yesTapped()
        coughVc.continueTapped()
        
        let anosmiaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(anosmiaVc.view)
        XCTAssertEqual(anosmiaVc.questionTitle, "ANOSMIA_QUESTION".localized)
        XCTAssertEqual(anosmiaVc.questionDetail, "ANOSMIA_DETAIL".localized)
        XCTAssertEqual(anosmiaVc.questionContext, "ANOSMIA_INITIAL_CONTEXT".localized)
        XCTAssertEqual(anosmiaVc.questionError, "ANOSMIA_ERROR".localized)
        XCTAssertEqual(anosmiaVc.questionYes, "ANOSMIA_YES".localized)
        XCTAssertEqual(anosmiaVc.questionNo, "ANOSMIA_NO".localized)
        anosmiaVc.yesTapped()
        anosmiaVc.continueTapped()
        
        let sneezeVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(sneezeVc.view)
        XCTAssertEqual(sneezeVc.questionTitle, "SNEEZE_QUESTION".localized)
        XCTAssertEqual(sneezeVc.questionDetail, "SNEEZE_DETAIL".localized)
        XCTAssertEqual(sneezeVc.questionContext, "SNEEZE_INITIAL_CONTEXT".localized)
        XCTAssertEqual(sneezeVc.questionError, "SNEEZE_ERROR".localized)
        XCTAssertEqual(sneezeVc.questionYes, "SNEEZE_YES".localized)
        XCTAssertEqual(sneezeVc.questionNo, "SNEEZE_NO".localized)
        sneezeVc.yesTapped()
        sneezeVc.continueTapped()
        
        let nauseaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(nauseaVc.view)
        XCTAssertEqual(nauseaVc.questionTitle, "NAUSEA_QUESTION".localized)
        XCTAssertEqual(nauseaVc.questionDetail, "NAUSEA_DETAIL".localized)
        XCTAssertEqual(nauseaVc.questionContext, "NAUSEA_INITIAL_CONTEXT".localized)
        XCTAssertEqual(nauseaVc.questionError, "NAUSEA_ERROR".localized)
        XCTAssertEqual(nauseaVc.questionYes, "NAUSEA_YES".localized)
        XCTAssertEqual(nauseaVc.questionNo, "NAUSEA_NO".localized)
        nauseaVc.yesTapped()
        nauseaVc.continueTapped()
        
        let summaryVC = try XCTUnwrap(navController.topViewController as? SymptomsSummaryViewController)
        XCTAssertNotNil(summaryVC.view);
        summaryVC.startDate = Date() // fake this for now
        summaryVC.buttonTapped(PrimaryButton())
        
        let submitVC = try XCTUnwrap(navController.topViewController as? SubmitSymptomsViewController)
        XCTAssertNotNil(submitVC.view)
        submitVC.confirmSwitch.isOn = true
        submitVC.submitTapped(PrimaryButton())
        
        XCTAssertEqual(resultingSymptoms, Symptoms([.temperature, .cough, .anosmia, .sneeze, .nausea]))
    }
    
    func testCheckin() throws {
        var resultingSymptoms: Symptoms?
        coordinator = make(type: .checkin, completion: { symptoms in
            resultingSymptoms = symptoms
        })
        
        coordinator.start()
        let tempVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(tempVc.view)
        XCTAssertEqual(tempVc.questionTitle, "TEMPERATURE_CHECKIN_QUESTION".localized)
        XCTAssertEqual(tempVc.questionDetail, "TEMPERATURE_DETAIL".localized)
        XCTAssertEqual(tempVc.questionError, "TEMPERATURE_CHECKIN_ERROR".localized)
        XCTAssertEqual(tempVc.questionYes, "TEMPERATURE_CHECKIN_YES".localized)
        XCTAssertEqual(tempVc.questionNo, "TEMPERATURE_CHECKIN_NO".localized)
        tempVc.yesTapped()
        tempVc.continueTapped()
        
        let coughVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(coughVc.view)
        XCTAssertEqual(coughVc.questionTitle, "COUGH_CHECKIN_QUESTION".localized)
        XCTAssertEqual(coughVc.questionDetail, "COUGH_DETAIL".localized)
        XCTAssertEqual(coughVc.questionError, "COUGH_CHECKIN_ERROR".localized)
        XCTAssertEqual(coughVc.questionYes, "COUGH_CHECKIN_YES".localized)
        XCTAssertEqual(coughVc.questionNo, "COUGH_CHECKIN_NO".localized)
        coughVc.yesTapped()
        coughVc.continueTapped()
        
        let anosmiaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(anosmiaVc.view)
        XCTAssertEqual(anosmiaVc.questionTitle, "ANOSMIA_CHECKIN_QUESTION".localized)
        XCTAssertEqual(anosmiaVc.questionDetail, "ANOSMIA_DETAIL".localized)
        XCTAssertEqual(anosmiaVc.questionError, "ANOSMIA_CHECKIN_ERROR".localized)
        XCTAssertEqual(anosmiaVc.questionYes, "ANOSMIA_CHECKIN_YES".localized)
        XCTAssertEqual(anosmiaVc.questionNo, "ANOSMIA_CHECKIN_NO".localized)
        anosmiaVc.yesTapped()
        anosmiaVc.continueTapped()
        
        let sneezeVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(sneezeVc.view)
        XCTAssertEqual(sneezeVc.questionTitle, "SNEEZE_CHECKIN_QUESTION".localized)
        XCTAssertEqual(sneezeVc.questionDetail, "SNEEZE_DETAIL".localized)
        XCTAssertEqual(sneezeVc.questionError, "SNEEZE_CHECKIN_ERROR".localized)
        XCTAssertEqual(sneezeVc.questionYes, "SNEEZE_CHECKIN_YES".localized)
        XCTAssertEqual(sneezeVc.questionNo, "SNEEZE_CHECKIN_NO".localized)
        sneezeVc.yesTapped()
        sneezeVc.continueTapped()
        
        let nauseaVc = try XCTUnwrap(navController.topViewController as? QuestionSymptomsViewController)
        XCTAssertNotNil(nauseaVc.view)
        XCTAssertEqual(nauseaVc.questionTitle, "NAUSEA_CHECKIN_QUESTION".localized)
        XCTAssertEqual(nauseaVc.questionDetail, "NAUSEA_DETAIL".localized)
        XCTAssertEqual(nauseaVc.questionError, "NAUSEA_CHECKIN_ERROR".localized)
        XCTAssertEqual(nauseaVc.questionYes, "NAUSEA_CHECKIN_YES".localized)
        XCTAssertEqual(nauseaVc.questionNo, "NAUSEA_CHECKIN_NO".localized)
        nauseaVc.yesTapped()
        nauseaVc.continueTapped()
        
        XCTAssertEqual(resultingSymptoms, Symptoms([.temperature, .cough, .anosmia, .sneeze, .nausea]))
    }
    
    private func make(type: QuestionnaireCoordinator.QuestionnaireType, completion: @escaping (Symptoms) -> Void = {_ in }) -> QuestionnaireCoordinator {
        
        return QuestionnaireCoordinator(navigationController: navController,
                                        statusStateMachine: StatusStateMachiningDouble(state: initialState(type: type)),
                                        questionnaireType: type,
                                        completion: completion
        )
    }
    
    private func initialState(type: QuestionnaireCoordinator.QuestionnaireType) -> StatusState {
        switch type {
        case .selfDiagnosis:
            return .ok(StatusState.Ok())
        case .checkin:
            // Symptoms & dates don't matter
            return .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: Date()))
        }
    }
    
}
