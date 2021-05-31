//
// Copyright (C) 2020 Curity AB.
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

extension URL {
    func withQuery(name: String, value: String) -> URL? {
        return withQuery(parameters: [name: value])
    }
    
    func withQuery(parameters: [String: String]) -> URL? {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)
        
        var queryItems = (urlComponents?.queryItems ?? []) as [URLQueryItem]
        for (name, value) in parameters {
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        
        urlComponents?.queryItems = queryItems
        
        return urlComponents?.url
    }

    var isHttpURL: Bool {
        return scheme == "https" || scheme == "http"
    }
}
