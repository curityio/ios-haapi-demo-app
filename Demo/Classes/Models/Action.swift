/*
 * Copyright (C) 2021 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation

protocol ActionModel: Decodable {}

class Action: Decodable {
    let template: Template
    let kind: String
    let model: ActionModel
    let title: String?
    let properties: [String: String]
    let continueActions: [Action]
    let uuid = UUID()

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
        case .unknown(let value):
            throw RepresentationError.unknownTemplate(value)
        }
    }
}
