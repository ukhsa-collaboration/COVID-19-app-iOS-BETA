//
//  DailyMetricsCollector.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol DefaultObjectStoring {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: DefaultObjectStoring {}

private let lastDailyMetricCollectionDateKey = "lastDailyMetricCollectionDate"

class DailyMetricsCollector {
    private let contactEventRepository: ContactEventRepository
    private let notificationCenter: NotificationCenter
    private let defaults: DefaultObjectStoring
    private let monitor: AppMonitoring
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    
    init(
        notificationCenter: NotificationCenter,
        contactEventRepository: ContactEventRepository,
        defaults: DefaultObjectStoring,
        monitor: AppMonitoring
    ) {
        self.contactEventRepository = contactEventRepository
        self.notificationCenter = notificationCenter
        self.monitor = monitor
        self.defaults = defaults

        notificationCenter.addObserver(self, selector: #selector(collectMetricsIfNeeded), name: UIApplication.significantTimeChangeNotification, object: nil)
        collectMetricsIfNeeded()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc private func collectMetricsIfNeeded() {
        if hasCollectedMetricsToday { return }
        collectMetrics()
        defaults.set(Date(), forKey: lastDailyMetricCollectionDateKey)
    }
    
    private func collectMetrics() {
        let events = contactEventRepository.contactEvents
        let yesterdayEvents = events.lazy.filter { self.calendar.isDateInYesterday($0.timestamp) }
        monitor.report(.collectedContactEvents(yesterday: yesterdayEvents.count, all: events.count))
    }
    
    private var hasCollectedMetricsToday: Bool {
        guard let lastCollectionDate = defaults.object(forKey: lastDailyMetricCollectionDateKey) as? Date else { return false }
        
        return lastCollectionDate > calendar.startOfDay(for: Date())
    }
}
