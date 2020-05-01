//
//  DailyMetricsCollectorTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class DailyMetricsCollectorTests: XCTestCase {
    
    private var notificationCenter: NotificationCenter!
    private var contactEventRepository: ContactEventRepositoryDouble!
    private var defaults: DefaultObjectStoringDouble!
    private var monitor: AppMonitoringDouble!
    private var collector: DailyMetricsCollector!

    override func setUp() {
        super.setUp()
        
        notificationCenter = NotificationCenter()
        contactEventRepository = ContactEventRepositoryDouble()
        defaults = DefaultObjectStoringDouble()
        monitor = AppMonitoringDouble()
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
    }
    
    func testMetricIsCollectedWithoutAnyEvents() {
        XCTAssertEqual(monitor.detectedEvents, [.collectedContactEvents(yesterday: 0, all: 0)])
    }
    
    func testMetricIsCollectedOnSignificantDateChange() {
        monitor.detectedEvents.removeAll()
        defaults.objects.removeAll()
        notificationCenter.post(name: UIApplication.significantTimeChangeNotification, object: nil)
        XCTAssertEqual(monitor.detectedEvents, [.collectedContactEvents(yesterday: 0, all: 0)])
    }
    
    func testStorageDateIsUpdatedAfterCollectingEvents() throws {
        let beforeDate = Date()
        defaults.objects.removeAll()
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
        XCTAssertEqual(defaults.objects.count, 1)
        let date = try XCTUnwrap(defaults.objects["lastDailyMetricCollectionDate"] as? Date)
        XCTAssertTrue(date > beforeDate)
        XCTAssertTrue(date < Date())
    }
    
    func testMetricIsCollectedIfItWasDoneMoreThanADayAgo() {
        // We can improve these tests with better day-boundary detection
        defaults.objects["lastDailyMetricCollectionDate"] = Date(timeIntervalSinceNow: -100_000)
        monitor.detectedEvents.removeAll()
        
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
        XCTAssertEqual(monitor.detectedEvents, [.collectedContactEvents(yesterday: 0, all: 0)])
    }
    
    func testMetricIsNotCollectedIfItWasDoneTodayAlready() {
        defaults.objects["lastDailyMetricCollectionDate"] = Date()
        monitor.detectedEvents.removeAll()
        
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
        XCTAssertEqual(monitor.detectedEvents, [])
    }
    
    func testMetricIsNotCollectedIfItWasDoneInAFutureDateSomehow() {
        defaults.objects["lastDailyMetricCollectionDate"] = Date(timeIntervalSinceNow: 100_000)
        monitor.detectedEvents.removeAll()
        
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
        XCTAssertEqual(monitor.detectedEvents, [])
    }
    
    func testMetricsAreCountedCorrectly() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let yesterday = calendar.startOfDay(for: Date()).addingTimeInterval(-20)
        let oldTime = Date(timeIntervalSinceNow: -1_000_000)

        let todayContactCounts = Int.random(in: 10...1000)
        let yesterdayContactCounts = Int.random(in: 10...1000)
        let olderContactCounts = Int.random(in: 10...1000)
        
        let dates = [
            Date(),
            yesterday,
            oldTime
        ]
        
        let counts = [
            todayContactCounts,
            yesterdayContactCounts,
            olderContactCounts,
        ]
        
        contactEventRepository.contactEvents = zip(dates, counts).lazy
            .flatMap { date, count -> Repeated<ContactEvent> in
            let event = ContactEvent(
                encryptedRemoteContactId: Data(),
                timestamp: date,
                rssiValues: [],
                rssiIntervals: [],
                duration: 0
            )
            return repeatElement(event, count: count)
        }
        
        defaults.objects.removeAll()
        monitor.detectedEvents.removeAll()
        collector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: defaults,
            monitor: monitor
        )
        
        let all = counts.reduce(0, +)
        XCTAssertEqual(monitor.detectedEvents, [.collectedContactEvents(yesterday: yesterdayContactCounts, all: all)])
    }
    
}

