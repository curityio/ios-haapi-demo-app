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

struct DisclosureView<ChildView: View>: View {
    let title: String
    let childView: ChildView

    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    init(title: String,
         @ViewBuilder childView: @escaping () -> ChildView)
    {
        self.title = title
        self.childView = childView()
    }

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.curityBody)
                    .fontWeight(.bold)
                    .padding([.leading])
                Spacer()
                if isExpanded {
                    Image("ChevronActive")
                } else {
                    Image("Chevron")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.primaryDark)
            .cornerRadius(8.0)
            .overlay(
                RoundedRectangle(cornerRadius: 8.0)
                    .stroke(Color.buttonBorder,
                            lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded = !isExpanded
            }
            // childView
            if isExpanded {
                childView
            }
        }
    }
}

struct DisclosureView_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureView(title: "Access Token") {
            CardView(text: "Hello World",
                     details: [
                        CardDetails(header: "expires_on",
                                    value: "300")
                     ])
        }
            .preferredColorScheme(.dark)
            .padding([.leading, .trailing])
    }
}
