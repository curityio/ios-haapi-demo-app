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

struct StateView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var flowViewModel: FlowViewModel
    @EnvironmentObject var imageLoader: ImageLoader
    
    @State var showHiddenFields = false
    @State var showParameters = false

    private var gridItemLayout = [
        GridItem(.fixed(15)),
        GridItem(.fixed(15))
    ]

    @ViewBuilder
    var body: some View {
        NavigationView {
            ScrollView {
                VStack (spacing: UIConstants.spacing) {
                    HeaderView(flowViewModel.title)
                    ForEach(flowViewModel.messages, id: \.self) { msg in
                        MessageView(text: msg.text,
                                    messageType: msg.messageType)
                    }
                    
                    contentView

                    if !flowViewModel.links.isEmpty {
                        LazyHGrid(rows: gridItemLayout,
                                  alignment: .top,
                                  spacing: UIConstants.spacing)
                        {
                            ForEach(flowViewModel.links, id: \.self) { link in
                                LinkView(viewModel: LinkViewModel(link: link,
                                                                  imageLoader: imageLoader,
                                                                  selectHandler:
                                                                    { link in
                                                                        flowViewModel.followLink(link: link)
                                                                    }))
                                    .disabled(flowViewModel.isProcessing)
                            }
                        }
                    }
                }
                .padding(.top, 32)
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
                title: Text("Client error"),
                message: Text(flowViewModel.error?.localizedDescription ?? ""),
                dismissButton: .default(Text("Ok"), action: {
                    presentationMode.wrappedValue.dismiss()
                    flowViewModel.reset()
                })
            )
        })
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
        if let pollingStep = flowViewModel.pollingStep {
            PollingView(viewModel: PollingViewModel(pollingStep: pollingStep,
                                                    controller: flowViewModel.controller,
                                                    automaticPolling: flowViewModel.automaticPolling))
        } else if let code = flowViewModel.code {
            AuthorizedView(viewModel: AuthorizedViewModel(authorizationCode: code,
                                                          controller: flowViewModel.controller))
        } else if let tokensRepresentation = flowViewModel.tokensRepresentation {
            TokensView(TokensViewModel(tokensRepresentation))
        } else if let selectorViewModel = flowViewModel.selectorViewModel {
            SelectorView(viewModel: selectorViewModel)
        } else if let formViewModel = flowViewModel.formViewModel {
            FormView(formViewModel: formViewModel)
        } else if let formOptions = flowViewModel.formOptions {
            ForEach(formOptions, id: \.id) { option in
                ProgressRow(title: option.title, action: {
                    if option.isSimpleForm {
                        flowViewModel.submitForm(form: option.formModel)
                    } else {
                        flowViewModel.applyAction(option.action)
                    }
                })
            }
        }
    }
}

struct StateView_Previews: PreviewProvider {
    static var previews: some View {
        StateView()
            .environmentObject(FlowViewModel(controller: HaapiController()))
    }
}
