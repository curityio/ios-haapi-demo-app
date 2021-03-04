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

class FormModel: ActionModel {
    let href: String
    let method: String
    let type: String?
    let title: String?
    let actionTitle: String?
    let fields: [Field]
    let continueActions: [Action]
    let uuid = UUID()

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

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.href = try container.decode(String.self, forKey: .href)
        self.method = try container.decode(String.self, forKey: .method)

        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.actionTitle = try container.decodeIfPresent(String.self, forKey: .actionTitle)
        self.fields = try container.decodeIfPresent([Field].self, forKey: .fields) ?? []
        self.continueActions = try container.decodeIfPresent([Action].self, forKey: .continueActions) ?? []
    }
    
    func isSimpleForm(includeHiddenFields: Bool = false) -> Bool {
        if fields.isEmpty && actionTitle == nil {
            return true
        }
        
        let hasNonHiddenFields = fields.contains { !$0.isHidden }
        
        return !(hasNonHiddenFields || includeHiddenFields)
    }
}
