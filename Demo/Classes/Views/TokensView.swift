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

    init(_ viewModel: TokensViewModel) {
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
            if viewModel.hasIDToken {
                DisclosureView(title: "ID Token") {
                    DisclosureContentView(text: viewModel.idToken)
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
        TokensView(TokensViewModel([
            "expires_in": "300",
            "refresh_token": "be9d3f8b-c18b-46b7-9asd-e0734d95c71d",
            "token_type": "bearer",
            "scope": "",
            "access_token": "6adf18ca-9d77-4947-945d-c939c8890977"
        ]))
    }
}

// MARK: - AccessTokenViewModel

struct TokensViewModel {
    let accessTokenRepresentation: [String: String]

    init(_ accessTokenRepresentation: [String: String]) {
        self.accessTokenRepresentation = accessTokenRepresentation
    }

    var hasIDToken: Bool {
        return accessTokenRepresentation["id_token"] != nil
    }

    var accessToken: String {
        return accessTokenRepresentation["access_token"] ?? ""
    }

    var details: [CardDetails] {
        return [
            CardDetails(header: "expires_in",
                        value: accessTokenRepresentation["expires_in"] ?? ""),
            CardDetails(header: "token_type",
                        value: accessTokenRepresentation["token_type"] ?? ""),
            CardDetails(header: "scope",
                        value: accessTokenRepresentation["scope"] ?? "")
        ]
    }

    var refreshToken: String {
        return accessTokenRepresentation["refresh_token"] ?? ""
    }

    var idToken: String {
        return accessTokenRepresentation["id_token"] ?? ""
    }
}
