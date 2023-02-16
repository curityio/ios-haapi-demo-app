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
import IdsvrHaapiSdk

struct StateView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var flowViewModel: FlowViewModel
    @EnvironmentObject var imageLoader: ImageLoader
    
    @State var showHiddenFields = false
    @State var showParameters = false

    @ViewBuilder
    var body: some View {
        NavigationView {
            ScrollView {
                VStack (spacing: UIConstants.spacing) {
                    HeaderView(flowViewModel.title, imageName: flowViewModel.imageLogo)
                    ForEach(flowViewModel.messageBundles, id: \.id) { msg in
                        MessageView(text: msg.text,
                                    messageType: msg.messageType)
                    }
                    contentView

                    if !(flowViewModel.haapiRepresentation is OAuthAuthorizationResponseStep),
                        let links = flowViewModel.haapiRepresentation?.links
                    {
                        let idLinks = links.map { LinkBundle(link: $0) }
                        ForEach(idLinks, id: \.id) { linkBundle in
                            LinkView(viewModel: LinkViewModel(link: linkBundle.link,
                                                              imageLoader: imageLoader,
                                                              selectHandler:
                                                                { link in
                                                                    flowViewModel.followLink(link: link)
                                                                }))
                                .disabled(flowViewModel.isProcessing)
                        }
                    }
                }
                .padding([.top, .bottom], 32)
                .navigationBarItems(trailing: trailingBarItem)
                .configureNavigationBar { navigationCtrl in
                    navigationCtrl.navigationBar.titleTextAttributes = [
                        NSAttributedString.Key.foregroundColor: UIColor(Color.textHeadings),
                        NSAttributedString.Key.font: UIFont.curityNavTitle
                    ]
                    navigationCtrl.navigationBar.backgroundColor = UIColor(Color.primaryDark)
                    navigationCtrl.navigationBar.isTranslucent = false
                    navigationCtrl.navigationBar.prefersLargeTitles = false
                }
                .paddingContentView()
            }
            .background(Color.primaryMedium)
        }
        
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: .constant(flowViewModel.error != nil), content: {
            Alert(
                title: Text(flowViewModel.error?.title ?? ""),
                message: Text(flowViewModel.error?.reason ?? ""),
                dismissButton: .default(Text("Ok"), action: {
                    presentationMode.wrappedValue.dismiss()
                    flowViewModel.reset()
                })
            )
        })
        .onChange(of: flowViewModel.tokenResponse) { arg in
            if arg != nil {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder
    private var trailingBarItem: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
            flowViewModel.reset()
        }) {
            Image(systemName: "xmark")
        }
        .padding([.leading, .top, .bottom])
        .padding([.trailing], 4)
        .accentColor(.textHeadings)
    }

    @ViewBuilder
    private var contentView: some View {
        if let selectorViewModel = flowViewModel.selectorViewModel {
            SelectorView(viewModel: selectorViewModel)
        } else if !flowViewModel.formViewModels.isEmpty { // Form
            ForEach(flowViewModel.formViewModels, id: \.self) { viewModel in
                FormView(formViewModel: viewModel)
            }
        } else if let authorizedViewModel = flowViewModel.authorizedViewModel {
            AuthorizedView(viewModel: authorizedViewModel)
        } else if let pollingViewModel = flowViewModel.pollingViewModel {
            PollingView(viewModel: pollingViewModel)
        } else if let genericHaapiViewModel = flowViewModel.genericHaapiViewModel {
            GenericHaapiView(viewModel: genericHaapiViewModel)
        }
        else if let webauthnViewModel = flowViewModel.webauthnViewModel {
            WebauthnAuthenticatorsView(viewModel: webauthnViewModel)
        }
        else {
            EmptyView()
        }
    }
}

// MARK: - UI Models helpers

struct LinkBundle: Identifiable {
    let link: IdsvrHaapiSdk.Link

    var id: String {
        return link.href
    }
}

struct ErrorInfo {
    let title: String?
    let reason: String
}

struct MessageBundle: Identifiable {
    let id: String = UUID().uuidString
    let text: String
    let messageType: MessageType
}
