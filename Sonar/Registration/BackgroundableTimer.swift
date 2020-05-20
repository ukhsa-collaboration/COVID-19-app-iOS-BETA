//
//  BackgroundableTimer.swift
//  Sonar
//
//  Created by NHSX on 5/20/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

// Ensures that a scheduled block will run either when the deadline expires or the next time the app
// is foregrounded after the deadline expires. (DispatchQueue.asyncAfter will sometimes provide the
// latter behavior, but it isn't consistent or reliable.)
class BackgroundableTimer {
    
    private let notificationCenter: NotificationCenter
    private let queue: TestableQueue
    private var nextTaskId: Int
    private var tasks: [Int:ScheduledTask]
    
    init(notificationCenter: NotificationCenter, queue: TestableQueue) {
        self.notificationCenter = notificationCenter
        self.queue = queue
        self.nextTaskId = 0
        self.tasks = [:]
        
        notificationCenter.addObserver(self, selector: #selector(foregrounded(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func schedule(deadline: DispatchTime, execute: @escaping @convention(block) () -> Void) {
        let taskId = nextTaskId
        nextTaskId += 1
        tasks[taskId] = ScheduledTask(deadline: deadline, execute: execute)

        queue.asyncAfter(deadline: deadline) {
            
            print("asyncAfter callback called for timer id \(taskId)")
            guard self.tasks[taskId] != nil else { return }
            self.tasks.removeValue(forKey: taskId)
            execute()
        }
    }
    
    @objc private func foregrounded(_ notification: NSNotification) {
        tasks = tasks.filter({ kv in
            if kv.value.isExpired {
                kv.value.execute()
                return false
            } else {
                return true
            }
        })
    }
}

private struct ScheduledTask {
    let deadline: DispatchTime
    let execute: () -> Void
    
    var isExpired: Bool { deadline <= .now() }
}
