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

import os
import UIKit

private let logger = Logger()

enum ClientOperationManager {
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
    func startOperation(haapiRedirect: HaapiRedirectable, onCompletion: @escaping (Bool) -> Void) {
        logger.info("Executing client-operation \(self.name)")
    }
    
    func continueOperation(url: URL, haapiSubmiter: HaapiSubmitable) {
        logger.info("Handling URL with client-operation \(self.name): \(url)")
    }
}
