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

class ClientOperationModel: ActionModel {
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        
        self.arguments = try container.decodeIfPresent([String: String].self, forKey: .arguments) ?? [:]
        self.continueActions = try container.decodeIfPresent([Action].self, forKey: .continueActions) ?? []
        self.errorActions = try container.decodeIfPresent([Action].self, forKey: .errorActions) ?? []
    }
}
