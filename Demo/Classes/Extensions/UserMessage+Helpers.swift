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

import SwiftUI
import HaapiModelsSDK

extension UserMessage {

    var messageType: MessageType {
        let result: MessageType

        if classList.contains("warn") {
            result = .warning
        }
        else if classList.contains("info") {
            result = .info
        }
        else if classList.contains("error") {
            result = .error
        }
        else if classList.contains("help") {
            result = .help
        }
        else if classList.contains("heading") {
            result = .heading
        }
        else {
            result = .unsupported(classList.first ?? "empty")
        }

        return result
    }
}

// MARK: - MessageType

enum MessageType: Equatable {

    case error
    case warning
    case info
    case heading
    case help
    case unsupported(String)

    var imageName: String? {
        let result: String?
        switch self {
        case .error:
            result = "WarningTriangle"
        case .warning, .info:
            result = "WarningCircle"
        default:
            result = nil
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
        default:
            result = .text
        }

        return result
    }

    func backgroundColor(_ colorScheme: ColorScheme) -> Color {
        guard self == .error || self == .warning || self == .info else { return .clear }
        let result: Color

        if colorScheme == .light {
            result = foregroundColor.opacity(0.08)
        } else {
            result = foregroundColor
        }

        return result
    }

    var font: Font {
        let result: Font

        switch self {
        case .error, .info, .warning:
            result = .curitySubheadline
        default:
            result = .text
        }

        return result
    }

    var textAlignment: TextAlignment {
        let result: TextAlignment

        switch self {
        case .error, .warning, .info:
            result = .leading
        default:
            result = .center
        }
        return result
    }
}
