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

import Foundation

/// Tokens Representation for the final step of the flow (AccessToken / RefreshToken or/and IDToken).
struct TokensRepresentation: Codable, Equatable {
    /// An `accessToken` is used to access your application resources
    let accessToken: String
    /// A `tokenType` like "bearer"
    let tokenType: String?
    /// A `scope` contains a list of scopes separated by a space. This list is configured in the initial request
    let scope: String?
    /// `expiresIn` is the number of seconds the `accessToken` is valid
    let expiresIn: Int
    /// A `refreshToken` is used to get a new `accessToken`
    let refreshToken: String
    /// `idToken` is present only if "openId" is included in the initial request
    let idToken: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}
