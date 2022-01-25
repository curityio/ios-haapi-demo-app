//
// Copyright (C) 2021 Curity AB.
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

import IdsvrHaapiSdk
import SwiftUI

struct TokensView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var flowViewModel: FlowViewModel
    
    @ObservedObject var viewModel: TokensViewModel

    init(viewModel: TokensViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .bottom) {
                    Spacer()
                    Button(action: {
                        flowViewModel.clearTokenResponse()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                    .padding([.leading, .top, .bottom])
                    .padding([.trailing], 4)
                    .accentColor(.textHeadings)
                }
                Image("Checkmark")
                    .padding()

                if let userInfo = viewModel.userInfo {
                    Text(userInfo)
                }

                // Access Token
                DisclosureView(title: "Access token") {
                    DisclosureContentView(text: viewModel.accessToken,
                                          details: viewModel.details)
                }
                // ID Token
                if let idToken = viewModel.idToken {
                    DisclosureView(title: "ID Token") {
                        DisclosureContentView(text: idToken)
                    }
                }
                // Refresh Token
                DisclosureView(title: "Refresh Token") {
                    DisclosureContentView(text: viewModel.refreshToken)
                }

                ColorButton(title: "Refresh token") { btn in
                    viewModel.requestRefreshToken()
                    btn.reset()
                }

                ColorButton(title: "Sign out") { btn in
                    flowViewModel.clearTokenResponse()
                    presentationMode.wrappedValue.dismiss()
                    btn.reset()
                }
            }
            .padding([.top, .bottom], 32)
            .paddingContentView()
        }
    }
}

// MARK: - AccessTokenViewModel

final class TokensViewModel: ObservableObject {

    @Published private(set) var oauthTokenResponse: SuccessfulTokenResponse
    @Published private(set) var userInfo: String?
    let oauthTokenManager: OAuthTokenManager
    let urlSession: URLSession
    let tokenEndpointURL: URL

    init(_ oauthTokenResponse: SuccessfulTokenResponse,
         oauthTokenConfiguration: OAuthTokenConfigurable,
         urlSession: URLSession)
    {
        self.oauthTokenResponse = oauthTokenResponse
        self.oauthTokenManager = OAuthTokenManager(oauthTokenConfiguration: oauthTokenConfiguration)
        self.urlSession = urlSession
        self.tokenEndpointURL = oauthTokenConfiguration.tokenEndpointURL
            .deletingLastPathComponent().appendingPathComponent("userinfo")

        fetchUserInfo()
    }

    var accessToken: String {
        return oauthTokenResponse.accessToken
    }

    var details: [CardDetails] {
        return [
            CardDetails(header: "expires_in",
                        value: "\(oauthTokenResponse.expiresIn)"),
            CardDetails(header: "token_type",
                        value: oauthTokenResponse.tokenType ?? ""),
            CardDetails(header: "scope",
                        value: oauthTokenResponse.scope ?? "")
        ]
    }

    var refreshToken: String {
        return oauthTokenResponse.refreshToken ?? ""
    }

    var idToken: String? {
        return oauthTokenResponse.idToken
    }

    func requestRefreshToken() {
        guard let refreshToken = oauthTokenResponse.refreshToken else { return }
        oauthTokenManager.refreshAccessToken(with: refreshToken) { oAuthResponse in
            if case let .successfulToken(tokenResponse) = oAuthResponse {
                DispatchQueue.main.async {
                    self.oauthTokenResponse = tokenResponse
                    self.fetchUserInfo()
                }
            }
        }
    }

    private func fetchUserInfo() {
        var urlRequest = URLRequest(url: tokenEndpointURL,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: 20)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("bearer \(oauthTokenResponse.accessToken)", forHTTPHeaderField: "Authorization")
        urlSession.dataTask(with: urlRequest) { [weak self] data, _, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard error == nil, let data = data else {
                    self.userInfo = nil
                    return
                }

                guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    self.userInfo = nil
                    return
                }

                self.userInfo = userInfo.description
            }
        }
        .resume()
    }
}
