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

class Problem: NSObject{
    let representation: Representation
    
    fileprivate init(representation: Representation) {
        self.representation = representation
    }
}

final class InvalidInputProblem: Problem {

    override fileprivate init(representation: Representation) {
        super.init(representation: representation)
    }
    
    var invalidFields: [InvalidField] {
        return representation.invalidFields
    }
}

struct InvalidField: Codable, Equatable {
    let name: String
    let reason: String?
    let detail: String?
}

final class AuthorizationProblem: Problem {

    var errorDescription: String {
        var result = ""
        for (index, content) in representation.messages.enumerated() {
            result.append(content.text)
            if index != representation.messages.count - 1 {
                result.append("\n")
            }
        }

        return result
    }

    var error: HaapiControllerError? {
        guard representation.code == "authorization_failed" || // timeout
                representation.code == "access_denied" || // bankid switching config while polling
                representation.code == nil // polling timeout
        else {
            return nil
        }

        return .problem(problem: self)
    }

    override var description: String {
        return errorDescription
    }
}

struct ProblemFactory {
    private init() {}

    static func create(_ representation: Representation) -> Problem? {
        switch representation.type {
        case .problem, .incorrectCredentialsProblem:
            return Problem(representation: representation)
        case .invalidInputProblem:
            return InvalidInputProblem(representation: representation)
        case .unexpected:
            return AuthorizationProblem(representation: representation)
        default:
            return nil
        }
    }
}
