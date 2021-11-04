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

import SwiftUI
import os

struct ColorButton: View {
    let title: String
    let buttonType: ButtonType
    let textPadding: Edge.Set
    private var action: (ColorButton) -> Void
    @State private var isSpinning = false

    init(title: String,
         buttonType: ButtonType = .primary,
         textPadding: Edge.Set = [],
         action: @escaping ((ColorButton) -> Void))
    {
        self.title = title
        self.buttonType = buttonType
        self.textPadding = textPadding
        self.action = action
    }

    var body: some View {
        Button(action: didTapButton) {
            Text(LocalizedStringKey(title))
                .opacity(isSpinning ? 0.0 : 1.0)
                .padding(textPadding)
        }
        .opacity(isSpinning ? 0.7 : 1.0)
        .disabled(isSpinning)
        .overlay(
            ArcSpinner(color: buttonType.foregroundColor)
                .opacity(isSpinning ? 1 : 0.0)
        )
        .buttonStyle(ColorButtonStyle(buttonTheme: buttonType.buttonTheme))
    }

    func didTapButton() {
        isSpinning = true
        action(self)
    }
}

extension ColorButton: Resettable {
    
    func reset() {
        isSpinning = false
    }
}

struct ColorButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ColorButton(title: "Create an account", action: { _ in })
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - ButtonType

enum ButtonType {
    case primary
    case secondary

    var foregroundColor: Color {
        let result: Color
        switch self {
        case .primary:
            result = .white
        case .secondary:
            result = Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1)
        }

        return result
    }

    var buttonTheme: ButtonThemable {
        let result: ButtonThemable
        switch self {
        case .primary:
            result = ButtonTheme(foregroundColor: foregroundColor,
                                 backgroundColor: .primaryRegular)
        case .secondary:
            result = ButtonTheme(foregroundColor: foregroundColor,
                                 backgroundColor: .secondaryAction,
                                 borderColor: Color.buttonBorder)
        }

        return result
    }
}

// MARK: - ColorButtonStyle

struct ColorButtonStyle: ButtonStyle {

    let buttonTheme: ButtonThemable

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(buttonTheme.foregroundColor)
            .font(buttonTheme.font)
            .frame(maxWidth: .infinity, minHeight: buttonTheme.minHeight)
            .background(buttonTheme.backgroundColor)
            .cornerRadius(buttonTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: buttonTheme.cornerRadius)
                    .stroke(buttonTheme.borderColor, lineWidth: 2)
            )
            .compositingGroup()
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Theming

protocol ButtonThemable {
    var foregroundColor: Color { get }
    var backgroundColor: Color { get }
    var borderColor: Color { get }

    var font: Font { get }
    var cornerRadius: CGFloat { get }
    var minHeight: CGFloat { get }
}

struct ButtonTheme: ButtonThemable {
    let foregroundColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let font: Font
    let cornerRadius: CGFloat
    let minHeight: CGFloat

    init(foregroundColor: Color,
         backgroundColor: Color,
         borderColor: Color = .clear,
         font: Font = Font.actionText,
         cornerRadius: CGFloat = UIConstants.cornerRadius,
         minHeight: CGFloat = UIConstants.buttonHeight)
    {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.font = font
        self.cornerRadius = cornerRadius
        self.minHeight = minHeight
    }
}
