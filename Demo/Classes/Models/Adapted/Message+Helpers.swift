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
import SwiftUI

extension Message {

    var messageType: MessageType {
        let result: MessageType

        if classList.contains("warn") {
            result = .warning
        }
        else if classList.contains("info") {
            result = .info
        }
        else { // error or heading which is not supported by messageType
            result = .error
        }

        return result
    }
}

// MARK: - MessageType

enum MessageType {

    case error
    case warning
    case info

    var imageName: String {
        let result: String
        switch self {
        case .error:
            result = "WarningTriangle"
        case .warning, .info:
            result = "WarningCircle"
        }

        return result
    }

    var foregroundColor: Color {
        let result: Color
        switch self {
        case .error:
            result = .error
        case .warning:
            result = .warning
        case .info:
            result = .info
        }

        return result
    }

    func backgroundColor(_ colorScheme: ColorScheme) -> Color {
        let result: Color

        if colorScheme == .light {
            result = foregroundColor.opacity(0.08)
        } else {
            result = foregroundColor
        }

        return result
    }
}
