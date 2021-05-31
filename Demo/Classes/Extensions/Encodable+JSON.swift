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

extension Encodable {
    func asJsonString(prettyPrinted: Bool = false) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = prettyPrinted ? [.prettyPrinted] : []
            let jsonData = try encoder.encode(self)
            let string = String(data: jsonData, encoding: .utf8)
            return string
        } catch {
            print("Error generating json: \(error.localizedDescription)")
            return nil
        }
    }
}

extension String {
    func decodedAsJson<T: Decodable>(as type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
