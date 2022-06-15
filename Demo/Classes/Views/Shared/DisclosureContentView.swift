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
    let decodeJWTModels: [DecodeJWTModel]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @Environment(\.colorScheme) var colorScheme

    init(text: String,
         details: [CardDetails] = [],
         decodeJWTModels: [DecodeJWTModel] = [])
    {
        self.text = text
        self.details = details
        self.decodeJWTModels = decodeJWTModels
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
                if !decodeJWTModels.isEmpty {
                    ForEach(decodeJWTModels, id: \.title) { model in
                        DecodeJWTView(model: model)
                            .frame(maxWidth: .infinity)
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
        DisclosureContentView(text: "Hello World",
                              decodeJWTModels: [
                                DecodeJWTModel(title: "HEADER",
                                               contents: [
                                                DecodeJWTContent(name: "iss",
                                                                 value: "https://localhost:8443/dev/oauth/anonymous"),
                                                DecodeJWTContent(name: "iat",
                                                                 value: 137_213_891_273)
                                               ])
                              ])
    }
}

struct CardDetails: Hashable {
    let header: String
    let value: String
}
