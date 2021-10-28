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
import os

class Problem: NSObject, HaapiStateContentable{
    let representation: Representation
    let actions: [Action] = []
    
    fileprivate init(representation: Representation) {
        self.representation = representation
    }

    var title: String {
        return representation.title ?? "Error(s)"
    }

    /// The code of the Representation
    var code: String? {
        return representation.code
    }

    /// The array of messages of the Representation and based on the Representation.invalidFields
    var messages: [Message] {
        var messages: [Message] = representation.invalidFields.compactMap {
            guard let detail = $0.detail else { return nil }
            return Message.invalid(text: detail)
        }
        messages.append(contentsOf: representation.messages)

        return messages
    }

    var haapiError: HaapiControllerError? {
        guard representation.type == .unexpected ||
                representation.code == "authorization_failed" ||
                representation.code == "access_denied" ||
                representation.code == nil
        else {
            return nil
        }

        return .problem(problem: self)
    }

    override var description: String {
        if let errorDesc = representation.errorDescription {
            return errorDesc
        }

        var result = ""
        for (index, content) in representation.messages.enumerated() {
            result.append(content.text)
            if index != representation.messages.count - 1 {
                result.append("\n")
            }
        }

        return result
    }
}

final class InvalidInputProblem: Problem {

    override fileprivate init(representation: Representation) {
        super.init(representation: representation)
    }
    
    var invalidFields: [InvalidField] {
        return representation.invalidFields
    }

    var errorDescription: String? {
        return representation.errorDescription
    }

    override var haapiError: HaapiControllerError? {
        return nil
    }
}

struct InvalidField: Codable, Equatable {
    let name: String
    let reason: String?
    let detail: String?
}

final class AuthorizationProblem: Problem {

    let errorDescription: String
    let error: String

    init(representation: Representation, errorDescription: String, error: String) {
        self.errorDescription = errorDescription
        self.error = error
        super.init(representation: representation)
    }

    override var title: String {
        return error
    }

    override var description: String {
        return errorDescription
    }

    override var haapiError: HaapiControllerError? {
        return .problem(problem: self)
    }
}

struct ProblemFactory {
    private init() {}

    static func create(_ representation: Representation) -> Problem? {
        switch representation.type {
        case .problem, .incorrectCredentialsProblem, .unexpected:
            return Problem(representation: representation)
        case .invalidInputProblem:
            return InvalidInputProblem(representation: representation)
        case .errorAuthorizationResponse:
            if let errorDescription = representation.errorDescription, let error = representation.error {
                return AuthorizationProblem(representation: representation,
                                            errorDescription: errorDescription,
                                            error: error)
            } else {
                Logger.clientApp.debug("Invalid representation for .errorAuthorizationResponse.")
                return nil
            }
        default:
            return nil
        }
    }
}
