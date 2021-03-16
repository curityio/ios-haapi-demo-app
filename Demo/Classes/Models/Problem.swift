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

class Problem {
    let representation: Representation
    
    fileprivate init(representation: Representation) {
        self.representation = representation
    }
    
    static func from(_ representation: Representation) -> Problem? {
        switch representation.type {
        case .problem:
            fallthrough
        case .incorrectCredentialsProblem:
            return Problem(representation: representation)
        case .invalidInputProblem:
            return InvalidInputProblem(representation: representation)
        default:
            return nil
        }
    }
}

class InvalidInputProblem: Problem {
    fileprivate override init(representation: Representation) {
        super.init(representation: representation)
    }
    
    var invalidFields: [InvalidField] {
        return representation.invalidFields
    }
}

struct InvalidField: Decodable {
    let name: String
    let reason: String?
    let detail: String?
}
