//
// Copyright (C) 2020 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
        
        timer = Timer.scheduledTimer(withTimeInterval: withTimeInterval, repeats: true) { _ in
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
