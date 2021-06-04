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

struct DisclosureContentView: View {
    let text: String
    let details: [CardDetails]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @Environment(\.colorScheme) var colorScheme

    init(text: String,
         details: [CardDetails] = [])
    {
        self.text = text
        self.details = details
    }

    var body: some View {
        VStack (alignment: .leading, spacing: UIConstants.spacing) {
            Group {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .light ? .spotGreen : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, UIConstants.spacing)
                if !details.isEmpty {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(details, id: \.self) { item in
                            Text(item.header)
                                .fontWeight(.medium)
                            Text(item.value)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.text)
                        .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureContentView(text: "Hello World",
                              details: [
                                CardDetails(header: "expires_on",
                                            value: "300")
                              ])
        DisclosureContentView(text: "Hello World",
                              details: [])
    }
}

struct CardDetails: Hashable {
    let header: String
    let value: String
}
