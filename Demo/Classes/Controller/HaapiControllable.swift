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

typealias HaapiControllable = HaapiFlowable & HaapiSubmitable & HaapiRedirectable

protocol HaapiFlowable: AnyObject {

    func start(with profile: Profile,
               completionHandler: HaapiCompletionHandler?)

    func getAccessToken(_ code: String,
                        completionHandler: HaapiCompletionHandler?)

    func reset()
}

protocol HaapiSubmitable: AnyObject {

    func submitForm(form: FormModel,
                    parameterOverrides: [String: String],
                    completionHandler: HaapiCompletionHandler?)

    func followLink(link: Link,
                    completionHandler: HaapiCompletionHandler?)
}

protocol HaapiRedirectable: AnyObject {

    func handleURL(_ url: URL)

    func handleContinueActions(continueActions: [Action],
                               completionHandler: HaapiCompletionHandler?)
}

// MARK: - Default parameters

extension HaapiSubmitable {
    
    func submitForm(form: FormModel,
                    parameterOverrides: [String: String] = [:],
                    completionHandler: HaapiCompletionHandler? = nil)
    {
        submitForm(form: form, parameterOverrides: parameterOverrides, completionHandler: completionHandler)
    }
}

extension HaapiRedirectable {

    func handleContinueActions(continueActions: [Action],
                               completionHandler: HaapiCompletionHandler? = nil)
    {
        handleContinueActions(continueActions: continueActions, completionHandler: completionHandler)
    }
}
