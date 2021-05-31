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

import Foundation
import os

class TrustAllCertsDelegate: NSObject, URLSessionDelegate {
    let logger = Logger()

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        logger.trace("Session Authentication challenge received")

        var credential: URLCredential?
        let serverTrust = challenge.protectionSpace.serverTrust
        if let serverTrust = serverTrust {
            logger.debug("Trusting certificate")
            credential = URLCredential(trust: serverTrust)
        }

        completionHandler(.useCredential, credential)
    }
}
