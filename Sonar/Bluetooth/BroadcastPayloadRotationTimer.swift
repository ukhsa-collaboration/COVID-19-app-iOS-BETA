//
//  BroadcastPayloadRotationTimer.swift
//  Sonar
//
//  Created by NHSX on 12.05.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class BroadcastPayloadRotationTimer {
    
    let broadcaster: BTLEBroadcaster
    let queue: DispatchQueue
    
    var timer: DispatchSourceTimer?
    
    init(broadcaster: BTLEBroadcaster, queue: DispatchQueue) {
        self.broadcaster = broadcaster
        self.queue = queue
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.setEventHandler {
            logger.info("updating identity at midnight UTC")
            self.broadcaster.updateIdentity()
        }
    }
    
    func scheduleNextMidnightUTC() {
        let now = Date()
        let secondsToMidnightUTC = now.followingMidnightUTC.timeIntervalSince(now)
        
        // Helpfully the docs say, "The system may fire a timer sooner than the value in the
        // wallDeadline parameter."—how much sooner? A day? A week? A nanosecond? Hopefully an
        // extra second is enough to ensure this fires strictly after midnight.
        //
        // Note we also don't bother rescheduling this timer, as we assume the app won't run
        // foregrounded for over 24h, and it gets scheduled on startup.
        timer?.schedule(wallDeadline: .now() + secondsToMidnightUTC + 1)
        timer?.resume()
    }

}

private let logger = Logger(label: "BTLE")
