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

class RedirectionStep {
    let redirectForm: FormModel
    
    private init(redirectForm: FormModel) {
        self.redirectForm = redirectForm
    }
    
    static func fromRepresentation(_ representation: Representation) -> RedirectionStep? {
        if case .redirectionStep = representation.type,
           representation.actions.count == 1,
           let action = representation.actions.first {
            return RedirectionStep.fromAction(action)
        }
        
        return nil
    }
    
    static func fromAction(_ action: Action) -> RedirectionStep? {
        if action.kind == "redirect",
           let form = action.model as? FormModel {
            return RedirectionStep(redirectForm: form)
        }
        
        return nil
    }
}
