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

struct ProblemView: View {
    let viewModel: ProblemViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.title)
                .foregroundColor(.error)
                .fixedSize(horizontal: false, vertical: true)
                .padding([.top, .bottom], 11)
            
            if let messages = viewModel.messages, !messages.isEmpty {
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

// swiftlint:disable force_try force_unwrapping
struct ProblemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProblemView(viewModel: example1)
            ProblemView(viewModel: example2)
        }
    }

    static var example1: ProblemViewModel = {
        let problem = ProblemFactory.create(try! Representation(Data(.incorrectCredentialsProblem)))!
        return ProblemViewModel(title: problem.representation.title ?? "",
                                messages: problem.representation.messages)
    }()

    static var example2: ProblemViewModel = {
        let problem = ProblemFactory.create(try! Representation(Data(.incorrectCredentialsProblemWithMessages)))!
        return ProblemViewModel(title: problem.representation.title ?? "",
                                messages: problem.representation.messages)
    }()
}

// MARK: - ProblemViewModel

struct ProblemViewModel {
    let title: String
    let messages: [Message]?
}
