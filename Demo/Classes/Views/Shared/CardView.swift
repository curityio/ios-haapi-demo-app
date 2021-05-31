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

struct CardView: View {
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
                    .foregroundColor(colorScheme == .light ? .blue : .textParagraphs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !details.isEmpty {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(details, id: \.self) { item in
                            Text(item.header)
                                .foregroundColor(colorScheme == .light ? .textParagraphs : .spotGreen)
                                .fontWeight(.medium)
                            Text(item.value)
                                .foregroundColor(.textParagraphs)
                                .fontWeight(.medium)
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .padding([.leading])
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
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(text: "Hello World",
                 details: [
                    CardDetails(header: "expires_on",
                                value: "300")
                 ])
        CardView(text: "Hello World",
                 details: [])
    }
}

struct CardDetails: Hashable {
    let header: String
    let value: String
}
