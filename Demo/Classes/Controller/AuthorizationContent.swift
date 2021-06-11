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

/// A model representing `HaapiState.authorizationResponse`. The relevant parameter of this model is **code**.
struct AuthorizationContent: HaapiStateContenable, Equatable {
    let representation: Representation
    let actions: [Action]
    /// The code that represents the authorization code. With it, you can retrieve the `OAuthTokenResponse`.
    let code: String

    init?(representation: Representation) {
        guard let code = representation.properties["code"] else {
            return nil
        }
        self.representation = representation
        self.actions = representation.actions
        self.code = code
    }
}
