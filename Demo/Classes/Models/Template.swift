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

enum Template: Codable {
    case clientOperation
    case form
    case selector
    case unsupported(value: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        self.init(rawValue: value.lowercased())
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .unsupported(let value):
            try container.encode(value)
        default:
            try container.encode(rawValue)
        }
    }
}

extension Template: RawRepresentable, Equatable, Hashable {
    typealias RawValue = String

    private enum Constants {
        static let clientOperation = "client-operation"
        static let form = "form"
        static let selector = "selector"
    }

    init(rawValue: String) {
        switch rawValue {
        case Constants.clientOperation:
            self = .clientOperation
        case Constants.form:
            self = .form
        case Constants.selector:
            self = .selector
        default:
            self = .unsupported(value: rawValue)
        }
    }

    var rawValue: RawValue {
        switch self {
        case .clientOperation:
            return Constants.clientOperation
        case .form:
            return Constants.form
        case .selector:
            return Constants.selector
        case .unsupported(let value):
            return value
        }
    }
}
