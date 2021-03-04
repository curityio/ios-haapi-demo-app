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

enum Template: Decodable, Equatable, Hashable {
    case clientOperation
    case form
    case selector
    case unknown(value: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value.lowercased() {
        case "client-operation":
            self = .clientOperation
        case "form":
            self = .form
        case "selector":
            self = .selector
        default:
            self = .unknown(value: value)
        }
    }
}
