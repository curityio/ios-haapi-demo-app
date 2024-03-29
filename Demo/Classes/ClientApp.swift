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
import SwiftUI
import IdsvrHaapiSdk

@main
struct ClientApp: App {
    @StateObject var flowViewModel = FlowViewModel()
    @StateObject var profileManager = ProfileManager()
    @StateObject var imageLoader = ImageLoader(with: .dev)
    
    init() {
        HaapiLogger.followUpTags = SdkFollowUpTag.allCases
        HaapiLogger.isInfoEnabled = true
        HaapiLogger.isSensitiveValueMasked = true
        HaapiLogger.isDebugEnabled = false
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: flowViewModel)
                .environmentObject(profileManager)
                .environmentObject(imageLoader)
                .onOpenURL(perform: handleUrl)
        }
    }
    
    func handleUrl(url: URL) {
        Logger.clientApp.debug("Incoming URL: \(url)")
        if flowViewModel.canHandleURL(url) {
            flowViewModel.handleURL(url)
        }
    }
}
