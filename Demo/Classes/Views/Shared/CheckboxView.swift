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

struct CheckboxView: View {
    private let localizedStringKey: LocalizedStringKey
    @Binding var isChecked: Bool
    private let checkboxSize: CGSize
    private let rightCheckedImage: Image?

    // Internal reference in order to update the View
    @State private var checked = false

    init(_ localizedStringKey: LocalizedStringKey,
         isChecked: Binding<Bool>,
         checkboxSize: CGSize,
         rightCheckedImage: Image?)
    {
        self.localizedStringKey = localizedStringKey
        self._isChecked = isChecked
        self.checkboxSize = checkboxSize
        self.rightCheckedImage = rightCheckedImage
    }

    init(_ strValue: String,
         isChecked: Binding<Bool>,
         checkboxSize: CGSize = CGSize(width: 36, height: 36),
         rightCheckedImage: Image? = nil)
    {
        self.init(LocalizedStringKey(strValue),
                  isChecked: isChecked,
                  checkboxSize: checkboxSize,
                  rightCheckedImage: rightCheckedImage)
    }

    var body: some View {
        HStack {
            Button(action: toggle) {
                HStack (spacing: 19.0) {
                    Image(checked ? "CheckboxChecked" : "CheckboxUnchecked")
                        .resizable()
                        .frame(width: checkboxSize.width,
                               height: checkboxSize.height)
                    Text(localizedStringKey)
                        .font(.curitySubheadline)
                        .foregroundColor(.text)
                        .frame(minHeight: 43.0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if checked, let rightCheckedImage = rightCheckedImage {
                rightCheckedImage
            }
        }
        .padding([.top], UIConstants.spacing)
        .onAppear(perform: {
            checked = isChecked
        })
    }

    func toggle() {
        checked = !checked
        isChecked = checked
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CheckboxView("Lorem ipsum dolor sit amet, consectetur.",
                         isChecked: .constant(true))
            CheckboxView("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi molestie nisl.",
                         isChecked: .constant(false))
        }
    }
}
