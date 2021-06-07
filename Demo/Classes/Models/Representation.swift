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

enum RepresentationError: Error {
    case unknownTemplate(_ name: String)
    case notAProblem // har-de-har
}

enum RepresentationType: Codable, Equatable {
    case authenticationStep
    case continueSameStep
    case redirectionStep
    case userConsentStep
    case oauthAuthorizationResponse
    case pollingStep
    case problem(value: String)
    case incorrectCredentialsProblem
    case invalidInputProblem
    case unexpected
    case unknown(value: String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        self.init(rawValue: value.lowercased())
    }
}

extension RepresentationType: RawRepresentable {
    typealias RawValue = String

    private enum Constants {
        static let authenticationStep = "authentication-step"
        static let continueSameStep = "continue-same-step"
        static let redirectionStep = "redirection-step"
        static let userConsentStep = "user-consent-step"
        static let oauthAuthorizationResponse = "oauth-authorization-response"
        static let pollingStep = "polling-step"
        static let incorrectCredentialsProblem = "https://curity.se/problems/incorrect-credentials"
        static let invalidInputProblem = "https://curity.se/problems/invalid-input"
        static let unexpected = "https://curity.se/problems/unexpected"

        static let problemPrefix = "https://curity.se/problems/"
    }

    // swiftlint:disable:next cyclomatic_complexity
    init(rawValue: String) {
        switch rawValue {
        case Constants.authenticationStep:
            self = .authenticationStep
        case Constants.continueSameStep:
            self = .continueSameStep
        case Constants.redirectionStep:
            self = .redirectionStep
        case Constants.userConsentStep:
            self = .userConsentStep
        case Constants.oauthAuthorizationResponse:
            self = .oauthAuthorizationResponse
        case Constants.pollingStep:
            self = .pollingStep
        case Constants.incorrectCredentialsProblem:
            self = .incorrectCredentialsProblem
        case Constants.invalidInputProblem:
            self = .invalidInputProblem
        case Constants.unexpected:
            self = .unexpected
        default:
            if rawValue.starts(with: Constants.problemPrefix) {
                self = .problem(value: rawValue)
            } else {
                self = .unknown(value: rawValue)
            }
        }
    }

    var rawValue: String {
        switch self {
        case .authenticationStep:
            return Constants.authenticationStep
        case .continueSameStep:
            return Constants.continueSameStep
        case .redirectionStep:
            return Constants.redirectionStep
        case .userConsentStep:
            return Constants.userConsentStep
        case .oauthAuthorizationResponse:
            return Constants.oauthAuthorizationResponse
        case .pollingStep:
            return Constants.pollingStep
        case .incorrectCredentialsProblem:
            return Constants.incorrectCredentialsProblem
        case .invalidInputProblem:
            return Constants.invalidInputProblem
        case .unexpected:
            return Constants.unexpected
        case .problem(let value):
            return value
        case .unknown(let value):
            return value
        }
    }
}

struct Representation: Decodable {
    let type: RepresentationType
    let metadata: [String: String]
    let actions: [Action]
    let links: [Link]
    let messages: [Message]
    let properties: [String: String]
    let invalidFields: [InvalidField]
    let title: String?
    let code: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case metadata
        case actions
        case links
        case messages
        case properties
        case invalidFields
        case title
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(RepresentationType.self, forKey: .type)

        self.messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        self.actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        self.links = try container.decodeIfPresent([Link].self, forKey: .links) ?? []
        self.properties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
        self.invalidFields = try container.decodeIfPresent([InvalidField].self, forKey: .invalidFields) ?? []
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.code = try container.decodeIfPresent(String.self, forKey: .code)
    }
}
