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

enum HaapiControllerError: Error, Equatable, LocalizedError {
    case invalidUrl
    case general(cause: Error)
    case noResponseData
    case serverError(statusCode: Int)
    case noCurrentState
    case problem(problem: Problem)
    case incorrectReset
    case none

    static func == (lhs: HaapiControllerError, rhs: HaapiControllerError) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.noResponseData, .noResponseData),
             (.noCurrentState, .noCurrentState),
             (.invalidUrl, .invalidUrl),
             (.incorrectReset, .incorrectReset):
            return true
        case (.general(let err1 as NSError), .general(let err2 as NSError)):
            return err1 == err2
        case (.problem(let prb1), .problem(let prb2)):
            return prb1 == prb2
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Internal error: an URL was invalid"
        case .general(let cause):
            return cause.localizedDescription
        case .noResponseData:
            return "Internal error: no data received"
        case .serverError(let code):
            return "Server error (\(code))"
        case .noCurrentState:
            return "Internal Error: invalid state"
        case .problem(let problem):
            return problem.description
        case .incorrectReset:
            return "Flow was reset while perfoming an action."
        case .none:
            return nil
        }
    }
}
