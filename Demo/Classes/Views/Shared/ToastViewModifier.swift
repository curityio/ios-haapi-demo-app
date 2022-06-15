//
// Copyright (C) 2022 Curity AB.
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

struct ToastViewModifier: ViewModifier {
    let message: String
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            toastView
        }
    }

    private var toastView: some View {
        VStack {
            if isShowing {
                Group {
                    Text(message)
                        .font(Font.text)
                        .padding(UIConstants.spacing)
                }
                .background(Color.greyLight)
                .cornerRadius(UIConstants.cornerRadius)
                .padding(UIConstants.spacing)
            }
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isShowing = false
            }
        }
        .animation(.linear(duration: 0.3), value: isShowing)
        .transition(.opacity)
    }
}

extension View {
    func configureToast(message: String, isShowing: Binding<Bool>) -> some View {
        modifier(ToastViewModifier(message: message, isShowing: isShowing))
    }
}
