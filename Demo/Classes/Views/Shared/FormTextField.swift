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

struct FormTextField: View {
    @Environment(\.colorScheme) var colorScheme

    let placeholder: String
    @Binding var text: String
    @Binding var isInvalid: Bool
    let textConfiguration: TextInputConfiguration

    @State var isPasswordHidden = false

    init(_ placeholder: String,
         text: Binding<String>,
         isInvalid: Binding<Bool>,
         config: TextInputConfiguration = .default)
    {
        self.placeholder = placeholder
        self._text = text
        self._isInvalid = isInvalid
        textConfiguration = config
    }

    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            Text(placeholder)
                .frame(maxWidth: .infinity, minHeight: 43.0, alignment: .leading)
                .font(.text)
                .foregroundColor(isInvalid ? .error : .text)
            HStack {
                CTextField(placeholder: placeholder,
                           text: $text,
                           textConfiguration: textConfiguration)
                    .hidePassword(isPasswordHidden)
                    .isInvalid(isInvalid)
                    .frame(minHeight: 48)
                if isInvalid {
                    Image(systemName: "exclamationmark.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.error)
                }
                if textConfiguration.isSecureTextEntry {
                    Spacer()
                        .frame(width: 8)
                    Button(action: {
                        toggleEye()
                    }, label: {
                        Image(systemName: isPasswordHidden ? "eye.slash" : "eye")
                    })
                    .frame(minHeight: 48)
                    .foregroundColor(.black)
                }
            }
            .padding([.leading, .trailing], 14)
            .background(Color.white)
            .cornerRadius(UIConstants.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .stroke(isInvalid ? Color.red : colorScheme == .light ? Color.grey : Color.primaryRegular,
                            lineWidth: UIConstants.lineWidth)
            )
        }
        .onAppear(perform: {
            isPasswordHidden = textConfiguration.isSecureTextEntry
        })
    }

    private func toggleEye() {
        guard textConfiguration.isSecureTextEntry else { return }
        isPasswordHidden = !isPasswordHidden
    }
}

struct FormTextField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            Group {
                FormTextField("Placeholder",
                              text: .constant("Hidden value"),
                              isInvalid: .constant(true),
                              config: .password)
                FormTextField("Placeholder",
                              text: .constant("Hidden value"),
                              isInvalid: .constant(false),
                              config: .password)
                FormTextField("Placeholder",
                              text: .constant("Clear value"),
                              isInvalid: .constant(false))
                FormTextField("Placeholder",
                              text: .constant("Clear value"),
                              isInvalid: .constant(true))
            }
            .padding([.leading, .trailing])
        }
    }
}
