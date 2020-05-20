//
//  BackgroundableTimerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/20/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class BackgroundableTimerTests: XCTestCase {

    func testSchedulesOnQueue() throws {
        let queue = QueueDouble()
        let timer = BackgroundableTimer(notificationCenter: NotificationCenter(), queue: queue)
        let deadline = DispatchTime.now()
        var called = false
        
        timer.schedule(deadline: deadline, execute: { called = true })
        
        XCTAssertEqual(queue.deadline, deadline)
        (try XCTUnwrap(queue.scheduledBlock))()
        XCTAssertTrue(called)
    }
    
    func testRunsCallbackOnForegroundIfExpiredAndNotAlreadyRun() {
        let notificationCenter = NotificationCenter()
        let queue = QueueDouble()
        let timer = BackgroundableTimer(notificationCenter: notificationCenter, queue: queue)
        var called = false

        timer.schedule(deadline: .now(), execute: { called = true })
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        XCTAssertTrue(called)
    }
    
    func testDoesNotRunNonExpiredCallbackOnForeground() {
        let notificationCenter = NotificationCenter()
        let queue = QueueDouble()
        let timer = BackgroundableTimer(notificationCenter: notificationCenter, queue: queue)
        var called = false

        timer.schedule(deadline: .now() + 30, execute: { called = true })
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        XCTAssertFalse(called)
    }
    
    func testDoesNotRunCallbackOnForegroundIfAlreadyRun() throws {
        let notificationCenter = NotificationCenter()
        let queue = QueueDouble()
        let timer = BackgroundableTimer(notificationCenter: notificationCenter, queue: queue)
        var called = false

        timer.schedule(deadline: .now(), execute: { called = true })
        (try XCTUnwrap(queue.scheduledBlock))()
        called = false
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        XCTAssertFalse(called)
    }
    
    func testDoesNotRunCallbackOnExpirationIfAlreadyRun() throws {
        let notificationCenter = NotificationCenter()
        let queue = QueueDouble()
        let timer = BackgroundableTimer(notificationCenter: notificationCenter, queue: queue)
        var called = false

        timer.schedule(deadline: .now(), execute: { called = true })
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        called = false
        (try XCTUnwrap(queue.scheduledBlock))()

        XCTAssertFalse(called)
    }
}
