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
    let viewModel: TokensViewModel
    let presentationMode: Binding<PresentationMode>

    init(viewModel: TokensViewModel,
         presentationMode: Binding<PresentationMode>) {
        self.viewModel = viewModel
        self.presentationMode = presentationMode
    }

    var body: some View {
        VStack {
            Image("Checkmark")
                .padding()
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
                presentationMode.wrappedValue.dismiss()
                btn.reset()
            }
        }
    }
}

// MARK: - AccessTokenViewModel

struct TokensViewModel {
    let oauthTokenResponse: TokenResponse
    let tokenServices: TokenServices

    init(_ oauthTokenResponse: TokenResponse,
         tokenServices: TokenServices)
    {
        self.oauthTokenResponse = oauthTokenResponse
        self.tokenServices = tokenServices
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
        tokenServices.refreshAccessToken(refreshToken: refreshToken)
    }
}
