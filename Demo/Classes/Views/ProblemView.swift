//
// Copyright (C) 2020 Curity AB.
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
import HaapiModelsSDK

struct ProblemView: View {
    let viewModel: ProblemViewModel

    var body: some View {
        VStack {
            if let title = viewModel.title {
                Text(title)
                    .foregroundColor(.error)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding([.top, .bottom], 11)
            }

            if let messages = viewModel.messages {
                VStack {
                    ForEach(messages, id: \.text) { message in
                        MessageView(text: message.text,
                                    messageType: message.messageType)
                    }
                }
            }
        }
    }
}

struct ProblemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProblemView(viewModel: ProblemViewModel(title: "A problem", messages: []))
            ProblemView(viewModel: ProblemViewModel(title: "A problem",
                                                    messages: [
                                                        ProblemMessageBundle(text: "Missing field",
                                                                             messageType: .error),
                                                        ProblemMessageBundle(text: "A help",
                                                                             messageType: .warning)
                                                    ]))
        }
    }
}

// MARK: - ProblemViewModel

struct ProblemViewModel {
    let title: String?
    let messages: [ProblemMessageBundle]
}

struct ProblemMessageBundle: Identifiable {
    var id: String {
        return UUID().uuidString
    }

    let text: String
    let messageType: MessageType
}
