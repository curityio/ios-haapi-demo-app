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

class BankIdClientOperation: ClientOperation {
    override init(model: ClientOperationModel) {
        super.init(model: model)
    }
    
    override func startOperation(haapiRedirect: HaapiRedirectable, onCompletion: @escaping (Bool) -> Void) {
        super.startOperation(haapiRedirect: haapiRedirect, onCompletion: onCompletion)
        
        guard let href = self.model.arguments["href"],
              let url = URL(string: href) else {
            logger.warning("No valid href in BankID client-operation arguments")
            onCompletion(false)
            return
        }
        
        UIApplication.shared.open(
            url,
            options: [.universalLinksOnly: false],
            completionHandler: { success in
                if success {
                    logger.debug("BankID successfully opened")
                } else {
                    logger.warning("BankID failed to open")
                }
                
                let actions = success ? self.model.continueActions : self.model.errorActions
                
                haapiRedirect.handleContinueActions(
                    continueActions: actions
                )
                
                // The HaapiController has been asked to process any existing continue actions immediately,
                // so we want to continue to be in a transitioning state until they complete
                onCompletion(true)
            }
        )
    }
}
