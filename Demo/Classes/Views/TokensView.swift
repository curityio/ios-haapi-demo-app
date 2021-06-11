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

import SwiftUI

struct TokensView: View {
    let viewModel: TokensViewModel

    init(viewModel: TokensViewModel) {
        self.viewModel = viewModel
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
        }
    }
}

struct AccessTokenView_Previews: PreviewProvider {
    static var previews: some View {
        TokensView(viewModel: TokensViewModel(OAuthTokenResponse(accessToken: "6adf18ca-9d77-4947-945d-c939c8890977",
                                                                 tokenType: "bearer",
                                                                 scope: nil,
                                                                 expiresIn: 300,
                                                                 refreshToken: "be9d3f8b-c18b-46b7-9asd-e0734d95c71d",
                                                                 idToken: nil)))
    }
}

// MARK: - AccessTokenViewModel

struct TokensViewModel {
    let oauthTokenResponse: OAuthTokenResponse

    init(_ oauthTokenResponse: OAuthTokenResponse) {
        self.oauthTokenResponse = oauthTokenResponse
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
        return oauthTokenResponse.refreshToken
    }

    var idToken: String? {
        return oauthTokenResponse.idToken
    }
}
