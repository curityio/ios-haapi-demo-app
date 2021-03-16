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
import IdsvrHaapiSdk
import os
import SwiftUI

private let logger = Logger()

@main
struct ClientApp: App {
    let haapiController: RuntimeHaapiController
    let globalSettings = GlobalSettings()
    let scheduler = Scheduler()
    
    init() {
        haapiController = try! RuntimeHaapiController(
            globalSettings: globalSettings
        )
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(haapiController: haapiController)
                .environmentObject(haapiController)
                .environmentObject(globalSettings)
                .environmentObject(scheduler)
                .onOpenURL(perform: self.handleUrl)
        }
    }
    
    func handleUrl(url: URL) {
        logger.debug("Incoming URL: \(url)")
        haapiController.currentState?.clientOperation?.continueOperation(url: url, haapiController: haapiController)
    }
}
