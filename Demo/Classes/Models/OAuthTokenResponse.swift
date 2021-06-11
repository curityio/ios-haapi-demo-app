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

/**
 A model representing an OAuthTokenResponse. It is used for the final step of the Haapi flow (AccessToken / RefreshToken or/and IDToken).

 Having this model enables the client to have access to the targeted resources.
 */
struct OAuthTokenResponse: Codable, Equatable {
    /// An `accessToken` is used to access your application resources
    let accessToken: String
    /// A `tokenType` like "bearer"
    let tokenType: String?
    /// A `scope` contains a list of granted scopes, separated by a space, which may be different from the requested scopes if the server decides it.
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

extension OAuthTokenResponse {

    /// The title that can be used in your View.
    var title: String {
        return NSLocalizedString("success_title",
                                 comment: "Title for final step in the flow")
    }

    /// The image name for building an UIImage(UIKit) or Image(SwiftUI) from your assetFolder.
    var imageLogo: String {
        return "Logo"
    }
}
