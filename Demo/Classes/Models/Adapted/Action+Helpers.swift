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
import UIKit

private let defaultImageName = "icon-user"

extension Action {

    var isRedirect: Bool {
        return kind == "redirect"
    }

    var authenticatorTypeImageName: String? {
        guard let authenticatorType = properties["authenticatorType"] else { return defaultImageName }

        var result = "icon-\(authenticatorType)"
        if UIImage(named: result) == nil {
            result = defaultImageName
        }
        return result
    }

    var buttonType: ButtonType {
        return kind == "cancel" ? .secondary : .primary
    }
}

extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.template == rhs.template
            && lhs.kind == rhs.kind
            && lhs.title == rhs.title
            && lhs.properties == rhs.properties
            && lhs.continueActions == rhs.continueActions
    }
}
