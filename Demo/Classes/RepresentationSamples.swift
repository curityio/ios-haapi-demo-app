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

import Foundation

enum RepresentationSamples: String {
    case redirect
    case selectAuthentication
    case selectAuthenticationWithLinks
    case bankidSelectSameOrOtherDevice
    case bankidSameDeviceClientOperation
    case usernamePassword
    case usernamePasswordFormErrors
    case duo
    case oauthAuthorizationResponse
    case launchExternalBrowser
    case incorrectCredentialsProblem
    case incorrectCredentialsProblemWithMessages
    case pollingStep
    case pollingStepDone
    case continueSameStep
    case messagesWithTextAndImageLinks
}

// MARK: Data

extension Data {

    enum URLError: Error {
        case noFile(String)
    }

    init(jsonFileName: String, inBundle bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: jsonFileName, withExtension: ".json") else {
            throw URLError.noFile("\(jsonFileName).json")
        }
        try self.init(contentsOf: url)
    }

    init(_ representationSamples: RepresentationSamples, in bundle: Bundle = .main) throws {
        try self.init(jsonFileName: representationSamples.rawValue, inBundle: bundle)
    }
}
