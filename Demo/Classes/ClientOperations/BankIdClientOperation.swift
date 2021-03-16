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

class BankIdClientOperation: ClientOperation {
    override init(model: ClientOperationModel) {
        super.init(model: model)
    }
    
    override func startOperation(haapiController: HaapiController, onCompletion: @escaping (Bool) -> Void) {
        super.startOperation(haapiController: haapiController, onCompletion: onCompletion)
        
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
                
                haapiController.handleContinueActions(
                    continueActions: actions,
                    onError: { _ in },
                    willCommitState: { _ in }
                )
                
                // The HaapiController has been asked to process any existing continue actions immediately,
                // so we want to continue to be in a transitioning state until they complete
                onCompletion(true)
            }
        )
    }
}
