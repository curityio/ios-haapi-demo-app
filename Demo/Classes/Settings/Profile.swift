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
import IdsvrHaapiSdk

struct Profile: Codable, Identifiable, Hashable {

    private static let CURITY_DEV_MODE = false

    private enum Constants {
        static let defaultName = "Default"
        static let scopes = ["openid", "profile"]

        static let defaultAuthorizationEndpointURI = "https://localhost:8443/oauth/v2/oauth-authorize"
        static let defaultTokenEndpointURI = "https://localhost:8443/oauth/v2/oauth-token"
        static let defaultUserinfoEndpointURI = "https://localhost:8443/oauth/v2/oauth-userinfo"
        static let defaultClientId = "haapi-ios-dev-client"
        static let defaultBaseURLString = "https://localhost:8443"
        static let defaultMetaBaseURLString = "https://localhost:8443/oauth/v2/oauth-anonymous"

        // Dev constants, for Curity developers' use
        static let defaultDevAuthorizationEndpointURI = "https://localhost:8443/dev/oauth/authorize"
        static let defaultDevTokenEndpointURI = "https://localhost:8443/dev/oauth/token"
        static let defaultDevUserinfoEndpointURI = "https://localhost:8443/dev/oauth/userinfo"
        static let defaultDevClientId = "haapi-ios-dev-client"
        static let defaultDevBaseURLString = "https://localhost:8443"
        static let defaultDevMetaBaseURLString = "https://localhost:8443/dev/oauth/anonymous"
    }

    var name: String
    var clientId: String
    var baseURLString: String
    var tokenEndpointURI: String = CURITY_DEV_MODE ? Constants.defaultDevTokenEndpointURI : Constants.defaultTokenEndpointURI
    var authorizationEndpointURI: String = CURITY_DEV_MODE ? Constants.defaultDevAuthorizationEndpointURI : Constants.defaultAuthorizationEndpointURI
    var userInfoEndpointURI: String = CURITY_DEV_MODE ? Constants.defaultDevUserinfoEndpointURI : Constants.defaultUserinfoEndpointURI
    var metaDataBaseURLString: String = CURITY_DEV_MODE ? Constants.defaultDevMetaBaseURLString : Constants.defaultMetaBaseURLString
    var followRedirects = true
    var automaticPolling = true
    var isDefaultAuthChallengeEnabled = false
    var supportedScopes: [String]? {
        didSet {
            guard let selectedScopes = selectedScopes, let supportedScopes = supportedScopes else {
                return
            }

            var filteredScopes = [String]()
            for scope in supportedScopes {
                if selectedScopes.contains(scope) {
                    filteredScopes.append(scope)
                }
            }

            self.selectedScopes = filteredScopes
        }
    }
    var selectedScopes: [String]? = Constants.scopes

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
                clientId: CURITY_DEV_MODE ? Constants.defaultDevClientId : Constants.defaultClientId,
                baseURLString: CURITY_DEV_MODE ? Constants.defaultDevMetaBaseURLString : Constants.defaultBaseURLString)
    }

    static func newProfile(_ val: Int) -> Profile {
        Profile(name: "New Profile (\(val))",
                clientId: CURITY_DEV_MODE ? Constants.defaultDevClientId : Constants.defaultClientId,
                baseURLString: CURITY_DEV_MODE ? Constants.defaultDevBaseURLString : Constants.defaultBaseURLString)
    }

    var haapiConfiguration: HaapiConfiguration? {
        guard let baseURL = URL(string: baseURLString),
              let tokenEndpointURL = URL(string: tokenEndpointURI),
              let authorizationEndpointURL = URL(string: authorizationEndpointURI),
              let appRedirect = Bundle.main.haapiRedirectURI else
        {
            return nil
        }

        let urlSession = URLSession(configuration: URLSessionConfiguration.haapiFlow,
                                    delegate: isDefaultAuthChallengeEnabled ? nil : TrustAllCertsDelegate(),
                                    delegateQueue: nil)
        return HaapiConfiguration(name: name,
                                  clientId: clientId,
                                  baseURL: baseURL,
                                  tokenEndpointURL: tokenEndpointURL,
                                  authorizationEndpointURL: authorizationEndpointURL,
                                  appRedirect: appRedirect,
                                  isAutoRedirect: followRedirects,
                                  urlSession: urlSession)
    }
}

private extension URLSessionConfiguration {

    static var haapiFlow: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20.0
        configuration.timeoutIntervalForResource = 20.0
        configuration.waitsForConnectivity = false

        return configuration
    }
}
