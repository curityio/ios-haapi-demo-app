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

class ExternalBrowserClientOperation: ClientOperation {
    override init(model: ClientOperationModel) {
        super.init(model: model)
    }
    
    override func startOperation(haapiRedirect: HaapiRedirectable, onCompletion: @escaping (Bool) -> Void) {
        super.startOperation(haapiRedirect: haapiRedirect, onCompletion: onCompletion)

        guard let href = self.model.arguments["href"],
              let url = URL(string: href) else {
            logger.warning("No valid href in external-browser client-operation arguments")
            onCompletion(false)
            return
        }

        guard let redirectURI = Bundle.main.haapiRedirectURI else {
            fatalError("URL Scheme was not configured for curity - this flow should not happen at this stage")
        }

        guard let urlWithRedirectUri = url.withQuery(name: "redirect_uri",
                                                     value: redirectURI)
        else {
            logger.warning("Could not create URL with redirect_uri")
            onCompletion(false)
            return
        }
        
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
    
    override func continueOperation(url: URL, haapiSubmiter: HaapiSubmitable) {
        super.continueOperation(url: url, haapiSubmiter: haapiSubmiter)
        
        guard model.continueActions.count == 1,
              let continueAction = model.continueActions.first,
              let form = continueAction.model as? FormModel else {
            logger.error("external-browser client-operation had none or more than one continue actions")
            return
        }
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let params = urlComponents.queryItems,
              let resumeNonce = params.first(where: { $0.name == "_resume_nonce" })?.value,
              !resumeNonce.isEmpty else {
            logger.error("Invalid Redirect URL received by external-browser client-operation: \(url)")
            return
        }
        
        haapiSubmiter.submitForm(
            form: form,
            parameterOverrides: ["_resume_nonce": resumeNonce]
        )
    }
}
