/*
 * Copyright (C) 2020 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation

enum RepresentationError: Error {
    case unknownTemplate(_ name: String)
    case notAProblem // har-de-har
}

enum RepresentationType: Decodable, CustomStringConvertible, Equatable {
    case authenticationStep
    case continueSameStep
    case redirectionStep
    case oauthAuthorizationResponse
    case pollingStep
    case problem(value: String)
    case incorrectCredentialsProblem
    case invalidInputProblem
    case unknown(value: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value.lowercased() {
        case "authentication-step":
            self = .authenticationStep
        case "continue-same-step":
            self = .continueSameStep
        case "redirection-step":
            self = .redirectionStep
        case "oauth-authorization-response":
            self = .oauthAuthorizationResponse
        case "polling-step":
            self = .pollingStep
        case "https://curity.se/problems/incorrect-credentials":
            self = .incorrectCredentialsProblem
        case "https://curity.se/problems/invalid-input":
            self = .invalidInputProblem
        default:
            if value.lowercased().starts(with: "https://curity.se/problems/") {
                self = .problem(value: value)
            } else {
                self = .unknown(value: value)
            }
        }
    }
    
    var description: String {
        switch self {
        case .authenticationStep:
            return "authentication-step"
        case .continueSameStep:
            return "continue-same-step"
        case .redirectionStep:
            return "redirection-step"
        case .oauthAuthorizationResponse:
            return "oauth-authorization-response"
        case .pollingStep:
            return "polling-step"
        case .problem(let value):
            return value
        case .incorrectCredentialsProblem:
            return "https://curity.se/problems/incorrect-credentials"
        case .invalidInputProblem:
            return "https://curity.se/problems/invalid-input"
        case .unknown(let value):
            return value
        }
    }
}

class Representation: Decodable {
    let type: RepresentationType
    let metadata: [String: String]
    let actions: [Action]
    let links: [Link]
    let messages: [Message]
    let properties: [String: String]
    let invalidFields: [InvalidField]
    let title: String?
    private(set) var originalJson: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case metadata
        case actions
        case links
        case messages
        case properties
        case invalidFields
        case title
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(RepresentationType.self, forKey: .type)

        self.messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        self.actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        self.links = try container.decodeIfPresent([Link].self, forKey: .links) ?? []
        self.properties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
        self.invalidFields = try container.decodeIfPresent([InvalidField].self, forKey: .invalidFields) ?? []
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
    }

    static func fromJson(_ json: String) throws -> Representation {
        try fromJson(json.data(using: .utf8)!)
    }

    static func fromJson(_ jsonData: Data) throws -> Representation {
        let representation = try JSONDecoder().decode(Representation.self, from: jsonData)
        representation.originalJson = jsonData.asPrettyJsonString()
        return representation
    }
}
