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

struct ProgressRow: View {
    var title: String
    var alignment: Alignment = .leading
    var action: () -> Void
    
    @State private var spinnerIsActive = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: didTapButton) {
            Text(title)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
                .overlay(
                    HStack(alignment: .center, content: {
                        Spacer()
                        if spinnerIsActive {
                            ProgressView()
                                .padding()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black)
                                )
                        }
                    })
                )
        }
        .disabled(spinnerIsActive)
    }

    func didTapButton() {
        self.spinnerIsActive = true
        action()
    }
}

struct ProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressRow(title: "Title", action: {  })
        }.environmentObject(HaapiController())
    }
}
