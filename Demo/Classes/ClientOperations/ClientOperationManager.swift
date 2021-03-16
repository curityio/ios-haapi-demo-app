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

import os
import UIKit

private let logger = Logger()

class ClientOperationManager {
    static func makeForActions(_ actions: [Action]) -> ClientOperation? {
        var clientOperation: ClientOperation?
        
        for action in actions {
            if let model = action.model as? ClientOperationModel {
                guard clientOperation == nil else {
                    logger.warning("More than one client-operation found in actions list: not supported.")
                    return nil
                }
                
                switch model.name {
                case "bankid":
                    clientOperation = BankIdClientOperation(model: model)
                case "external-browser-flow":
                    clientOperation = ExternalBrowserClientOperation(model: model)
                default:
                    logger.warning("Unknown client-operation: \(model.name)")
                }
            }
        }
        
        if let clientOperation = clientOperation {
            logger.info("Active client-operation: \(clientOperation.name)")
        } else {
            logger.debug("No client-operations")
        }
        
        return clientOperation
    }
}

class ClientOperation {
    let model: ClientOperationModel
    
    var name: String {
        return model.name
    }
    
    init(model: ClientOperationModel) {
        self.model = model
    }
    
    /// Start the client-operation
    /// - Parameter onCompletion: called when the client-operation has finnished execution. Returns true if the HaapiController should still be in a tranistioning state after execution.
    func startOperation(haapiController: HaapiController, onCompletion: @escaping (Bool) -> Void) {
        logger.info("Executing client-operation \(self.name)")
    }
    
    func continueOperation(url: URL, haapiController: HaapiController) {
        logger.info("Handling URL with client-operation \(self.name): \(url)")
    }
}
