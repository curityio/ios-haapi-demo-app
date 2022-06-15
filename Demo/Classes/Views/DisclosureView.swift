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

extension Notification.Name {
    static let copyToClipoard = Notification.Name("copyToClipoard")
}

struct DisclosureView<ChildView: View>: View {
    let title: String
    let childView: ChildView
    let textToClipboard: String

    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    init(title: String,
         textToClipboard: String? = nil,
         @ViewBuilder childView: @escaping () -> ChildView)
    {
        self.title = title
        self.childView = childView()
        if let textToClipboard = textToClipboard {
            self.textToClipboard = textToClipboard
        } else {
            self.textToClipboard = title
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.text)
                    .fontWeight(.medium)
                Spacer()
                Button {
                    UIPasteboard.general.string = textToClipboard

                    NotificationCenter.default
                        .post(name: NSNotification.Name.copyToClipoard,
                              object: nil)
                } label: {
                    Image("Copy")
                        .padding([.leading, .trailing], UIConstants.spacing)
                }
                if isExpanded {
                    Image("ChevronActive")
                } else {
                    Image("Chevron")
                }
            }
            // childView
            if isExpanded {
                childView
            }
        }
        .padding(.all, UIConstants.spacing)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.primaryDark)
        .cornerRadius(UIConstants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .stroke(Color.grey,
                        lineWidth: UIConstants.lineWidth)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded = !isExpanded
        }
    }
}

struct DisclosureView_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureView(title: "Access Token") {
            DisclosureContentView(text: "Hello World",
                                  details: [
                                    CardDetails(header: "expires_on",
                                                value: "300")
                                  ])
        }
        .preferredColorScheme(.light)
        .paddingContentView()
    }
}
