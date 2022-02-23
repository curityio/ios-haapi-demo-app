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

struct AuthorizedView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel: AuthorizedViewModel

    var body: some View {
        VStack {
            Text("Authorization Code:")
            Text(viewModel.authorizationCode).bold().padding()
            ColorButton(title: "Get Access token") { _ in
                viewModel.getAccessToken()
            }
        }
    }
}

struct AuthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizedView(viewModel: AuthorizedViewModel(authorizationCode: "0",
                                                      tokenServices: nil))
    }
}

class AuthorizedViewModel: ObservableObject {

    let authorizationCode: String
    weak var tokenServices: TokenServices?

    init(authorizationCode: String,
         tokenServices: TokenServices?)
    {
        self.authorizationCode = authorizationCode
        self.tokenServices = tokenServices
    }

    func getAccessToken() {
        tokenServices?.fetchAccessToken(code: authorizationCode)
    }
}
