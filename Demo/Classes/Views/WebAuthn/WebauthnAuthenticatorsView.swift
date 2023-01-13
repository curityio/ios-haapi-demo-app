//
// Copyright (C) 2023 Curity AB.
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
import IdsvrHaapiSdk

struct WebauthnAuthenticatorsView: View {
    @ObservedObject var viewModel: WebauthnAuthenticatorsViewModel
    
    var body: some View {
        header
        contentView
    }
    
    @ViewBuilder
    private var header: some View {
        if let problem = viewModel.problem {
            ProblemView(viewModel: problem)
        } else {
            EmptyView() }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.platformAuthenticatorAction != nil && viewModel.crossPlatforAuthenticatorAction != nil {
            VStack (alignment: .leading) {
                ColorButton(title: "webauthn_platform_button_text") { btn in
                    viewModel.platformAuthenticatorAction?()
                    btn.reset()
                }
                .padding([.top], UIConstants.spacing * 2)
                .padding([.bottom], UIConstants.smallSpacing)
                Text("webauthn_platform_message_text")
                    .font(.text)
                    .multilineTextAlignment(.center)
                    .padding([.bottom], UIConstants.spacing * 2)
                ColorButton(title: "webauthn_crossplatform_button_text") { btn in
                    viewModel.crossPlatforAuthenticatorAction?()
                    btn.reset()
                }
                .padding([.bottom], UIConstants.smallSpacing)
                Text("webauthn_crossplatform_message_text")
                    .font(.text)
                    .multilineTextAlignment(.center)
            }
            .paddingContentView()
        }
        else if viewModel.errorAction != nil {
            VStack (alignment: .leading) {
                if viewModel.retryAction != nil {
                    ColorButton(title: "webauthn_retry_button_text") { btn in
                        viewModel.retryAction?()
                        btn.reset()
                    }
                    .padding([.top], UIConstants.spacing)
                }
                ColorButton(title: "webauthn_error_button_text") { btn in
                    viewModel.errorAction?()
                    btn.reset()
                }
                .padding([.top], UIConstants.spacing)
            }
            .paddingContentView()
        }
        else { EmptyView() }
    }
}

struct WebauthnAuthenticatorsView_Previews: PreviewProvider {
    // swiftlint:disable:next line_length
    static let errorText = "An error has ocurred or WebAuthn is not supported by this device. Please open the browser instead to complete the flow or retry."
    // swiftlint:disable:next line_length
    static let problem = ProblemViewModel(title: "", messages: [ProblemMessageBundle(text: errorText, messageType: .error)])
    
    static var previews: some View {
        Group {
            
            WebauthnAuthenticatorsView(viewModel: WebauthnAuthenticatorsViewModel(platformAction: {},
                                                                                  crossPlatformAction: {}))
            WebauthnAuthenticatorsView(viewModel: WebauthnAuthenticatorsViewModel(problem: problem,
                                                                                  retryAction: {},
                                                                                  errorAction: {}))
                .previewDevice("iPhone 11 Pro")
        }
    }
}

// MARK: - FormViewModel
class WebauthnAuthenticatorsViewModel: NSObject, ObservableObject {
    let problem: ProblemViewModel?
    var platformAuthenticatorAction: (() -> Void)?
    var crossPlatforAuthenticatorAction: (() -> Void)?
    var retryAction: (() -> Void)?
    var errorAction: (() -> Void)?
    
    init(problem: ProblemViewModel? = nil,
         platformAction: (() -> Void)? = nil,
         crossPlatformAction: (() -> Void)? = nil,
         retryAction: (() -> Void)? = nil,
         errorAction: (() -> Void)? = nil)
    {
        self.problem = problem
        self.platformAuthenticatorAction = platformAction
        self.crossPlatforAuthenticatorAction = crossPlatformAction
        self.retryAction = retryAction
        self.errorAction = errorAction
    }
}
