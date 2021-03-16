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

enum FieldType: Decodable, Equatable, Hashable {
    case username
    case password
    case hidden
    case checkbox
    case unknown(value: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value.lowercased() {
        case "username": self = .username
        case "password": self = .password
        case "hidden"  : self = .hidden
        case "checkbox": self = .checkbox
        default: self = .unknown(value: value)
        }
    }
}

struct Field: Decodable, Hashable {
    let name: String
    let type: FieldType
    let label: String?
    let value: String?
    let placeholder: String?
    let uuid = UUID()
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case label
        case value
        case placeholder
    }
}

extension Field {
    var isHidden: Bool {
        if case .hidden = type {
            return true
        } else {
            return false
        }
    }
}
