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

struct FormModel: ActionModel, Identifiable {
    let href: String
    let method: String
    let type: String?
    let title: String?
    let actionTitle: String?
    let fields: [Field]
    let continueActions: [Action]
    let id = UUID()

    private enum CodingKeys: String, CodingKey {
        case href
        case method
        case type
        case title
        case actionTitle
        case fields
        case continueActions
    }

    init(href: String, method: String) {
        self.href = href
        self.method = method
        self.type = nil
        self.title = nil
        self.actionTitle = nil
        self.fields = []
        self.continueActions = []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.href = try container.decode(String.self, forKey: .href)
        self.method = try container.decode(String.self, forKey: .method)

        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.actionTitle = try container.decodeIfPresent(String.self, forKey: .actionTitle)
        self.fields = try container.decodeIfPresent([Field].self, forKey: .fields) ?? []
        self.continueActions = try container.decodeIfPresent([Action].self, forKey: .continueActions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(href, forKey: .href)
        try container.encode(method, forKey: .method)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(actionTitle, forKey: .actionTitle)
        if !fields.isEmpty {
            try container.encode(fields, forKey: .fields)
        }
        if !continueActions.isEmpty {
            try container.encode(continueActions, forKey: .continueActions)
        }
    }
}
