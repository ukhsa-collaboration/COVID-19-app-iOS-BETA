//
//  SubmitSymptomsViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/8/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SubmitSymptomsViewControllerTests: TestCase {

    var vc: SubmitSymptomsViewController!
    var statusStateMachine: StatusStateMachiningDouble!
    var completionSymptoms: Symptoms?

    override func setUp() {
        super.setUp()

        statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
    }
    
    func testSubmitTappedWithConfirmationSwitchOff() throws {
        let startDate = Date()
        makeSubject(
            symptoms: [.temperature],
            startDate: startDate
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)
        XCTAssertTrue(vc.errorView.isHidden)
        XCTAssertFalse(vc.confirmSwitch.isOn)
        
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertNil(statusStateMachine.selfDiagnosisCalled)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
        XCTAssertFalse(vc.errorView.isHidden)
        XCTAssertEqual(vc.confirmSwitch.layer.borderColor, UIColor(named: "NHS Error")!.cgColor)
    }

    func testSubmitTappedWithConfirmationSwitchOn() throws {
        let date = Date()
        makeSubject(
            symptoms: [.temperature],
            startDate: date
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.confirmSwitch.isOn = true
        let button = PrimaryButton()
        vc.submitTapped(button)

        let (symptoms, startDate) = try XCTUnwrap(statusStateMachine.selfDiagnosisCalled)
        XCTAssertEqual(symptoms, [.temperature])
        XCTAssertEqual(startDate, date)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
        XCTAssertTrue(vc.errorView.isHidden)
    }
    
    func testHasNoSymptoms() {
        makeSubject(symptoms: [])

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(statusStateMachine.selfDiagnosisCalled)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
    }

    func testSelfDiagnosesWhenOk() throws {
        statusStateMachine.state = .ok(StatusState.Ok())

        let date = Date()
        makeSubject(symptoms: [.temperature], startDate: date)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        let (symptoms, startDate) = try XCTUnwrap(statusStateMachine.selfDiagnosisCalled)
        XCTAssertEqual(symptoms, [.temperature])
        XCTAssertEqual(startDate, date)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
    }

    func testSelfDiagnosesWhenExposed() throws {
        statusStateMachine.state = .exposed(StatusState.Exposed(startDate: Date()))

        let date = Date()
        makeSubject(symptoms: [.temperature], startDate: date)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        let (symptoms, startDate) = try XCTUnwrap(statusStateMachine.selfDiagnosisCalled)
        XCTAssertEqual(symptoms, [.temperature])
        XCTAssertEqual(startDate, date)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
    }

    private func makeSubject(
        symptoms: Symptoms = [],
        startDate: Date = Date()
    ) {
        vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            symptoms: symptoms,
            startDate: startDate,
            statusStateMachine: statusStateMachine
        ) { self.completionSymptoms = $0 }
        XCTAssertNotNil(vc.view)
    }

}

fileprivate class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}
