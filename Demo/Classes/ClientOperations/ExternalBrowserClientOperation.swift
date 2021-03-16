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

class ExternalBrowserClientOperation: ClientOperation {
    override init(model: ClientOperationModel) {
        super.init(model: model)
    }
    
    override func startOperation(haapiController: HaapiController, onCompletion: @escaping (Bool) -> Void) {
        super.startOperation(haapiController: haapiController, onCompletion: onCompletion)
        
        guard let href = self.model.arguments["href"],
              let url = URL(string: href) else {
            logger.warning("No valid href in external-browser client-operation arguments")
            onCompletion(false)
            return
        }
        
        let urlWithRedirectUri = url.withQuery(name: "redirect_uri", value: Constants.redirectUri)
        
        UIApplication.shared.open(
            urlWithRedirectUri,
            completionHandler: { success in
                if success {
                    logger.debug("Browser successfully opened")
                } else {
                    logger.warning("Browser failed to open")
                }
                
                // No more processing is done until we're triggered by the redirect_uri,
                // so we want to end the transitioning state.
                onCompletion(false)
            }
        )
    }
    
    override func continueOperation(url: URL, haapiController: HaapiController) {
        super.continueOperation(url: url, haapiController: haapiController)
        
        guard model.continueActions.count == 1,
              let continueAction = model.continueActions.first,
              let form = continueAction.model as? FormModel else {
            logger.error("external-browser client-operation had none or more than one continue actions")
            return
        }
        
        guard let urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: true),
              let params = urlComponents.queryItems,
              let resumeNonce = params.first(where: { $0.name == "_resume_nonce" })?.value,
              !resumeNonce.isEmpty else {
            logger.error("Invalid Redirect URL received by external-browser client-operation: \(url)")
            return
        }
        
        haapiController.submitForm(
            form: form,
            parameterOverrides: ["_resume_nonce": resumeNonce],
            onError: { _ in },
            willCommitState: { _ in }
        )
    }
}
