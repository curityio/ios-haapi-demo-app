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

enum FieldType: Codable {
    case username
    case password
    case hidden
    case checkbox
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

extension FieldType: RawRepresentable, Equatable, Hashable {
    typealias RawValue = String

    init(rawValue: String) {
        switch rawValue {
        case "username": self = .username
        case "password": self = .password
        case "hidden"  : self = .hidden
        case "checkbox": self = .checkbox
        default: self = .unsupported(value: rawValue)
        }
    }

    var rawValue: RawValue {
        switch self {
        case .username:
            return "username"
        case .password:
            return "password"
        case .hidden:
            return "hidden"
        case .checkbox:
            return "checkbox"
        case .unsupported(let value):
            return value
        }
    }
}

struct Field: Codable, Hashable, Identifiable {
    let name: String
    let type: FieldType
    let label: String?
    let value: String?
    let placeholder: String?
    let id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case label
        case value
        case placeholder
    }
}
