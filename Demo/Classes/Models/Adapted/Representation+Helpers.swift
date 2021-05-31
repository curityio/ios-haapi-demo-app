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

extension Representation {

    init(_ data: Data) throws {
        self = try JSONDecoder().decode(Representation.self, from: data)
    }

    var pollForm: FormModel? {
        return actions.first(where: { $0.kind == "poll" })?.model as? FormModel
    }

    var cancelForm: FormModel? {
        return actions.first(where: { $0.kind == "cancel" })?.model as? FormModel
    }

    var redirectForm: FormModel? {
        return actions.first(where: { $0.kind == "redirect" })?.model as? FormModel
    }

    var formModel: FormModel? {
        guard actions.count == 1,
              let result = actions.first(where: { $0.kind == "form" })?.model as? FormModel
        else {
            return nil
        }

        return result
    }
}

extension Representation: Equatable {

    static func == (lhs: Representation, rhs: Representation) -> Bool {
        return lhs.type == rhs.type
            && lhs.metadata == rhs.metadata
            && lhs.properties == rhs.properties
            && lhs.title == rhs.title
            && lhs.invalidFields == rhs.invalidFields
            && lhs.messages == rhs.messages
            && lhs.links == rhs.links
            && lhs.actions == rhs.actions
    }
}
