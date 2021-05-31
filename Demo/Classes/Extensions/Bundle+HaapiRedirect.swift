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

extension Bundle {
    var haapiRedirectScheme: String? {
        guard let urlTypes = object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
              let firstElement = urlTypes.first as? [String: AnyObject],
              firstElement["CFBundleURLName"] as? String == "io.curity.haapi",
              let urlSchemes = firstElement["CFBundleURLSchemes"] as? [String]
        else {
            return nil
        }

        return urlSchemes.first
    }

    var haapiRedirectURI: String? {
        guard let scheme = haapiRedirectScheme else { return nil }

        return scheme + ":start"
    }
}
