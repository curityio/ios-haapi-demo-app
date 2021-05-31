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

protocol ActionModel: Codable {}

class Action: Codable, Identifiable {
    let template: Template
    let kind: String
    let model: ActionModel
    let title: String?
    let properties: [String: String]
    let continueActions: [Action]

    private enum CodingKeys: String, CodingKey {
        case template
        case kind
        case model
        case title
        case properties
        case continueActions
    }

    init(
        template: Template,
        kind: String,
        model: ActionModel,
        title: String? = nil,
        properties: [String: String] = [:],
        continueActions: [Action] = []
    ) {
        self.template = template
        self.kind = kind
        self.model = model
        self.title = title
        self.properties = properties
        self.continueActions = continueActions
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.template = try container.decode(Template.self, forKey: .template)
        self.kind = try container.decode(String.self, forKey: .kind)

        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.properties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
        self.continueActions = try container.decodeIfPresent([Action].self, forKey: .continueActions) ?? []
        
        switch template {
        case .clientOperation:
            self.model = try container.decode(ClientOperationModel.self, forKey: .model)
        case .form:
            self.model = try container.decode(FormModel.self, forKey: .model)
        case .selector:
            self.model = try container.decode(SelectorModel.self, forKey: .model)
        case .unsupported(let value):
            throw RepresentationError.unknownTemplate(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(template.rawValue, forKey: .template)
        try container.encode(kind, forKey: .kind)

        if let formModel = model as? FormModel {
            try container.encode(formModel, forKey: .model)
        }
        else if let clientOperationModel = model as? ClientOperationModel {
            try container.encode(clientOperationModel, forKey: .model)
        }
        else if let selectorModel = model as? SelectorModel {
            try container.encode(selectorModel, forKey: .model)
        }

        try container.encode(title, forKey: .title)

        if !properties.isEmpty {
            try container.encode(properties, forKey: .properties)
        }
        if !continueActions.isEmpty {
            try container.encode(continueActions, forKey: .continueActions)
        }
    }
}
