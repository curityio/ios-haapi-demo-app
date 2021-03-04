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

enum PollingStatus {
    case pending
    case done
    case failed
    case unknown
}

class PollingStep {
    let representation: Representation
    
    private init(representation: Representation) {
        self.representation = representation
    }
    
    static func from(_ representation: Representation) -> PollingStep? {
        if case .pollingStep = representation.type {
            return PollingStep(representation: representation)
        }
        
        return nil
    }
    
    var status: PollingStatus {
        let status = representation.properties["status"]
        
        if status == "done" {
            return .done
        } else if status == "pending" {
            return .pending
        } else if status == "failed" {
            return .failed
        }
        
        return .unknown
    }
    
    var pollingForm: FormModel? {
        guard case .pending = status else {
            return nil
        }
        
        return representation.actions.first { $0.kind == "poll" }?.model as? FormModel
    }
    
    var cancelForm: FormModel? {
        guard case .pending = status else {
            return nil
        }
        
        return representation.actions.first { $0.kind == "cancel" }?.model as? FormModel
    }
    
    var doneForm: FormModel? {
        guard case .done = status else {
            return nil
        }
        
        // Not all authenticators will return a 'redirect' form when polling is 'done'.
        // If a single form is returned, we assume it to be the 'done' continue form.
        return redirectForm(allowNonRedirectIfAlone: true)
    }
    
    var failedForm: FormModel? {
        guard case .failed = status else {
            return nil
        }
        
        // Not all authenticators will return a 'redirect' form when polling is 'failed'.
        // If a single form is returned, we assume it to be the 'failed' continue form.
        return redirectForm(allowNonRedirectIfAlone: true)
    }
    
    private func redirectForm(allowNonRedirectIfAlone: Bool = false) -> FormModel? {
        if let redirectAction = representation.actions.first(where: { $0.kind == "redirect" }) {
            return redirectAction.model as? FormModel
        } else if allowNonRedirectIfAlone,
                  representation.actions.count == 1,
                  let action = representation.actions.first,
                  action.kind == "form" {
            return action.model as? FormModel
        } else {
            return nil
        }
    }
    
    var mainForm: FormModel? {
        return pollingForm ?? doneForm
    }
    
    var auxiliaryActions: [Action] {
        representation.actions
            .filter { action in
                switch status {
                case .done:
                    return action.kind != "redirect"
                case .pending:
                    return action.kind != "poll" && action.kind != "cancel"
                default:
                    return true
                }
            }
    }
}
