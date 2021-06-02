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

struct AuthenticatorButton: View {
    @Environment(\.colorScheme) var colorScheme

    private let imageName: String?
    private let title: LocalizedStringKey
    private let actionHandler: (Resettable) -> Void

    @State private var isSelected = false

    init(imageName: String?,
         title: LocalizedStringKey,
         actionHandler: @escaping (Resettable) -> Void)
    {
        self.imageName = imageName
        self.title = title
        self.actionHandler = actionHandler
    }

    var body: some View {
        Button(action: didSelect) {
            HStack (spacing: 11.0) {
                if !isSelected {
                    Image(imageName ?? "")
                        .resizable()
                        .frame(width: 26.0,
                               height: 26.0,
                               alignment: .center)
                    Text(title)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                } else {
                    ArcSpinner(color: Color.primaryRegular)
                }
            }
        }
        .buttonStyle(ColorButtonStyle(buttonTheme: ButtonTheme.authenticatorButton(for: colorScheme)))
    }

    func didSelect() {
        isSelected = true
        actionHandler(self)
    }
}

extension AuthenticatorButton: Resettable {

    func reset() {
        isSelected = false
    }
}

struct AuthenticatorButton_Previews: PreviewProvider {

    static var previews: some View {
        LazyVStack {
            AuthenticatorButton(imageName: "icon-twitter",
                                title: "Continue with Google",
                                actionHandler: { _ in })
            AuthenticatorButton(imageName: "icon-user",
                                title: "A Standard Active Directory backed Authenticator",
                                actionHandler: { _ in })
        }
        .preferredColorScheme(.dark)
        .padding()
        .previewDevice("iPod touch (7th generation)")
    }
}

private extension ButtonTheme {

    static func authenticatorButton(for colorScheme: ColorScheme) -> ButtonTheme {
        return ButtonTheme(foregroundColor: .black,
                           backgroundColor: .white,
                           borderColor: colorScheme == .light ? .buttonBorder : .clear,
                           font: .actionText,
                           cornerRadius: UIConstants.cornerRadius,
                           minHeight: UIConstants.buttonHeight)
    }
}
