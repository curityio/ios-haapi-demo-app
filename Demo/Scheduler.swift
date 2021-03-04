/*
 * Copyright (C) 2020 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation
import os

private let logger = Logger()

/// Rudimentary Scheduler. Only one task can be scheduled at a time
class Scheduler: ObservableObject {
    private var timer: Timer?
    private let semaphore = DispatchSemaphore(value: 1)
    
    func schedule(withTimeInterval: TimeInterval, task: @escaping () -> Void) {
        // Synchronizing method access
        semaphore.wait()
        defer {
            // Will be executed just before execution leaves the current block
            semaphore.signal()
        }
        
        if let currentTimer = timer {
            currentTimer.invalidate()
            logger.trace("Scheduled task was dropped because new task was scheduled")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: withTimeInterval, repeats: false) { _ in
            task()
        }
    }
    
    func invalidate() {
        // Synchronizing method access
        semaphore.wait()
        defer {
            // Will be executed just before execution leaves the current block
            semaphore.signal()
        }
        
        if let currentTimer = timer {
            currentTimer.invalidate()
            logger.trace("Scheduled task was dropped")
        }
        
        timer = nil
    }
}
