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

struct DecodeJWTView: View {
    let model: DecodeJWTModel

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack (alignment: .leading, spacing: UIConstants.spacing) {
            Text(model.title)
            Text("{")
            ForEach(model.contents, id: \.name) { value in
                Group {
                    HStack (alignment: .firstTextBaseline, spacing: 20) {
                        Text(value.name)
                            .foregroundColor(Color.info)
                        Text(value.stringValue)
                            .foregroundColor(value.foregroundColor)
                    }
                }
                .padding(.leading, 20.0)
            }
            Text("}")
        }
        .font(.system(.body, design: .monospaced))
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct DecodeJWTView_Previews: PreviewProvider {
    static var previews: some View {
        DecodeJWTView(
            model: DecodeJWTModel(title: "HEADER",
                                  contents: [
                                    DecodeJWTContent(name: "typ", value: "jwt"),
                                    DecodeJWTContent(name: "iat", value: 137_213_891_273),
                                    DecodeJWTContent(name: "iss", value:
                                                        "https://localhost:8443/dev/oauth/anonymous")
                                  ]
                                 )
        )
    }
}

struct DecodeJWTModel {
    let title: String
    let contents: [DecodeJWTContent]
}

struct DecodeJWTContent {
    let name: String
    let value: Any

    var stringValue: String {
        return "\(value)"
    }

    var foregroundColor: Color {
        switch value {
        case is Int, is Double:
            return Color.spotGreen
        default:
            return Color.warning
        }
    }
}
