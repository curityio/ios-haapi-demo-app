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

import SwiftUI
import UIKit
import os

struct MainView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var imageLoader: ImageLoader
    @ObservedObject var viewModel: FlowViewModel
    @State private var startFlow = false
    @State private var canOpenToken = false
    @State private var isShowingToast = false
    
    var body: some View {
        TabView {
            StartAuthView { button in
                viewModel.start(profileManager.activeProfile) { openSheet in
                    startFlow = openSheet
                    button.reset()
                }
            }
            .background(Color.primaryMedium)
            .tabItem {
                Label("Home",
                      systemImage: "house")
            }
            ProfileListView(profileManager: profileManager)
                .tabItem {
                    Label("Settings",
                          systemImage: "gear")
                }
        }
        .accentColor(.spotMagenta)
        .sheet(isPresented: $startFlow,
               onDismiss: {
                  canOpenToken = viewModel.tokenResponse != nil
                  viewModel.reset()
               },
               content: {
                  StateView()
                     .environmentObject(viewModel)
                     .environmentObject(imageLoader)
               })
        .fullScreenCover(isPresented: Binding<Bool>.constant(viewModel.tokenResponse != nil && canOpenToken),
                         onDismiss: {
                            canOpenToken = false
                         },
                         content: {
                            if let tokenResponse = viewModel.tokenResponse,
                               let haapiConfiguration = profileManager.activeProfile.haapiConfiguration
                            {
                                TokensView(viewModel: TokensViewModel(
                                    tokenResponse,
                                    oauthTokenConfiguration: haapiConfiguration,
                                    userinfoEndpointURL: profileManager.activeProfile.userInfoEndpointURI,
                                    urlSession: haapiConfiguration.urlSession))
                                    .environmentObject(viewModel)
                                    .configureToast(message: "copied_to_clipboard",
                                                    isShowing: $isShowingToast)
                            } else {
                                EmptyView()
                            }
                         })
        .alert(isPresented: Binding<Bool>.constant(viewModel.error != nil), content: {
            Alert(
                title: Text(viewModel.error?.title ?? ""),
                message: Text(viewModel.error?.reason ?? ""),
                dismissButton: .default(Text("Ok"), action: { viewModel.reset() })
            )
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.copyToClipoard)) { _ in
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isShowingToast = false
            }
        }
    }
}
