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
import UIKit

private let mainFont = "Roboto"

extension Font {

    static func curity(_ size: CGFloat,
                       relativeTo: Font.TextStyle) -> Font
    {
        return Font.custom(mainFont,
                           size: size,
                           relativeTo: relativeTo)
    }

    static var curitySubheadline: Font {
        return .curity(12.0, relativeTo: .subheadline)
    }

    static var curityTitle: Font {
        return .curity(40.0, relativeTo: .title)
    }

    static var curityTitle2: Font {
        return .curity(24.0, relativeTo: .title2)
    }

    static var curityBody: Font {
        return .curity(17.0, relativeTo: .body)
    }

    static var text: Font {
        return .curity(16, relativeTo: .body)
    }

    static var link: Font {
        return .curity(14.0, relativeTo: .footnote)
    }

    static var actionText: Font {
        return Font.curity(16, relativeTo: .body).weight(.medium)
    }
}

extension UIFont {

    static var curityNavTitle: UIFont {
        guard let titleFont = UIFont(name: mainFont, size: 17.0) else {
            fatalError("Missing font: Roboto")
        }
        let fontMetrics = UIFontMetrics(forTextStyle: .headline)
        
        return fontMetrics.scaledFont(for: titleFont)
    }

    static var text: UIFont {
        guard let font = UIFont(name: mainFont, size: 16.0) else {
            fatalError("Missing font: Roboto")
        }
        let fontMetrics = UIFontMetrics(forTextStyle: .body)

        return fontMetrics.scaledFont(for: font)
    }

    static var curitySubheadline: UIFont {
        guard let font = UIFont(name: mainFont, size: 12.0) else {
            fatalError("Missing font: Roboto")
        }
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)

        return fontMetrics.scaledFont(for: font)
    }
}
