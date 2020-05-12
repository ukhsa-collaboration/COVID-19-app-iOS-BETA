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
    var persistence: PersistenceDouble!
    var statusStateMachine: StatusStateMachiningDouble!
    var schedulerDouble: SchedulerDouble!

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        statusStateMachine = StatusStateMachiningDouble()
        schedulerDouble = SchedulerDouble()
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
        XCTAssertTrue(vc.errorLabel.isHidden)
        XCTAssertFalse(vc.confirmSwitch.isOn)
        
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertNil(statusStateMachine.selfDiagnosisCalled)
        XCTAssertNil(statusStateMachine.checkinSymptoms)
        XCTAssertFalse(vc.errorLabel.isHidden)
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
        XCTAssertTrue(vc.errorLabel.isHidden)
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
        statusStateMachine.state = .exposed(StatusState.Exposed(exposureDate: Date()))

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
        symptoms: Set<Symptom> = [],
        startDate: Date = Date()
    ) {
        vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persisting: persistence,
            contactEventsUploader: ContactEventsUploaderDouble(),
            symptoms: symptoms,
            startDate: startDate,
            statusViewController: nil,
            statusStateMachine: statusStateMachine,
            localNotificationScheduler: schedulerDouble
        )
        XCTAssertNotNil(vc.view)
    }

}

fileprivate class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}
