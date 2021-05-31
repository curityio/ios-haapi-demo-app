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

struct ClientOperationModel: ActionModel {
    let name: String
    let arguments: [String: String]
    let continueActions: [Action]
    let errorActions: [Action]
    
    private enum CodingKeys: String, CodingKey {
        case name
        case arguments
        case continueActions
        case errorActions
    }
    
    init(
        name: String,
        arguments: [String: String] = [:],
        continueActions: [Action] = [],
        errorActions: [Action] = []
    ) {
        self.name = name
        self.arguments = arguments
        self.continueActions = continueActions
        self.errorActions = errorActions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        
        self.arguments = try container.decodeIfPresent([String: String].self, forKey: .arguments) ?? [:]
        self.continueActions = try container.decodeIfPresent([Action].self, forKey: .continueActions) ?? []
        self.errorActions = try container.decodeIfPresent([Action].self, forKey: .errorActions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        if !arguments.isEmpty {
            try container.encode(arguments, forKey: .arguments)
        }
        if !continueActions.isEmpty {
            try container.encode(continueActions, forKey: .continueActions)
        }
        if !errorActions.isEmpty {
            try container.encode(errorActions, forKey: .errorActions)
        }
    }
}
