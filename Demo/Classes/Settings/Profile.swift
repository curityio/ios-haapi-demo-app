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
import SwiftUI

struct Profile: Codable, Identifiable, Hashable {

    private enum Constants {
        static let defaultAuthorizationEndpointURI = "https://localhost:8443/dev/oauth/authorize"
        static let defaultTokenEndpointURI = "https://localhost:8443/dev/oauth/token"
        static let defaultName = "Default"
        static let defaultClientId = "haapi-ios-dev-client"
        static let defaultBaseURLString = "https://localhost:8443"
        static let defaultMetaBaseURLString = "https://localhost:8443/dev/oauth/anonymous"
    }

    var name: String
    var clientId: String
    var baseURLString: String
    var tokenEndpointURI: String = Constants.defaultTokenEndpointURI
    var authorizationEndpointURI: String = Constants.defaultAuthorizationEndpointURI
    var metaDataBaseURLString: String = Constants.defaultMetaBaseURLString
    var followRedirects = true
    var automaticPolling = true
    var isDefaultAuthChallengeEnabled = false
    var supportedScopes: [String]?
    var selectedScopes: [String]?

    var fetchedAt: Date?

    var id = UUID()
}

extension Profile: Equatable {

    var isUsingSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var metaDataEndpointURL: URL? {
        let endpoint = metaDataBaseURLString.appending("/.well-known/openid-configuration")
        return URL(string: endpoint)
    }

    var errorBaseURLString: String? {
        if let url = URL(string: baseURLString),
           UIApplication.shared.canOpenURL(url) {
            return nil
        } else {
            return "This URL is invalid"
        }
    }
}

extension Profile {

    static var `default`: Profile {
        Profile(name: Constants.defaultName,
                clientId: Constants.defaultClientId,
                baseURLString: Constants.defaultBaseURLString)
    }

    static func newProfile(_ val: Int) -> Profile {
        Profile(name: "New Profile (\(val))",
                clientId: Constants.defaultClientId,
                baseURLString: Constants.defaultBaseURLString)
    }
}
