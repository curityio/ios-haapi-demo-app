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

struct ProfileView {
    // MARK: Properties

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ProfileViewModel

    @State private var isPulling = false
}

// MARK: View

extension ProfileView: View {

    var body: some View {
        VStack {
            List {
                Section(header: Text("Base configuration")) {
                    EditText(placeholder: "Name",
                             text: $viewModel.profile.name)
                    EditText(placeholder: "Client ID",
                             text: $viewModel.profile.clientId)
                    EditText(placeholder: "Base URL",
                             text: $viewModel.profile.baseURLString,
                             textInputConfiguration: .url,
                             errorMessage: viewModel.errorBaseURLString)
                }
                Section(header: Text("Meta data configuration"), footer: fetchedView) {
                    EditText(placeholder: "Meta data URL",
                             text: $viewModel.profile.metaDataBaseURLString,
                             textInputConfiguration: .url)
                    FetchButton(text: "Fetch latest configuration", isLoading: isPulling) {
                        isPulling = true
                        viewModel.pullMetaData {
                            isPulling = false
                        }
                    }
                    .accentColor(.blue)
                }

                Section(header: Text("Endpoints")) {
                    EditText(placeholder: "Token endpoint URI",
                             text: $viewModel.profile.tokenEndpointURI,
                             textInputConfiguration: .url,
                             errorMessage: viewModel.errorTokenEndpointURLString)
                    EditText(placeholder: "Authorization endpoint URI",
                             text: $viewModel.profile.authorizationEndpointURI,
                             textInputConfiguration: .url,
                             errorMessage: viewModel.errorAuthorizationEndpointString)
                }
                Section(header: Text("Supported Scopes")) {
                    if let scopeViewModel = viewModel.scopeViewModel {
                        ScopesView(viewModel: scopeViewModel)
                    } else {
                        Text("Unknown")
                    }
                }
                Section(header: Text("Toggles")) {
                    Toggle("Follow redirect", isOn: $viewModel.profile.followRedirects)
                    Toggle("Automatic polling", isOn: $viewModel.profile.automaticPolling)
                    Toggle("Enable SSL check", isOn: $viewModel.profile.isDefaultAuthChallengeEnabled)
                }
            }
            .navigationBarTitle(Text("Settings"))
            .navigationBarItems(trailing: trailingBarItem)
            .listStyle(GroupedListStyle())
        }
    }

    // MARK: ViewBuilders

    @ViewBuilder
    var fetchedView: some View {
        if let date = viewModel.profile.fetchedAt {
            Text("Last fetched: \(date.dateFormatted)")
                .italic()
        }
        else if let error = viewModel.error {
            Text("Error fetching configuration: \(error.localizedDescription)")
                .italic()
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var trailingBarItem: some View {
        if !viewModel.isActiveProfile {
            Button(action: {
                viewModel.apply()
                dismiss()
            }) {
                Text("Make active")
            }
            .accentColor(.primaryRegular)
        } else {
            EmptyView()
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(Profile.default, profileManager: ProfileManager()))
    }
}

// MARK: - Helper components

private struct EditText: View {

    let placeholder: String
    @Binding var text: String
    let textInputConfiguration: TextInputConfiguration
    let errorMessage: String?

    init(placeholder: String,
         text: Binding<String>,
         textInputConfiguration: TextInputConfiguration = .default,
         errorMessage: String? = nil)
    {
        self.placeholder = placeholder
        self._text = text
        self.textInputConfiguration = textInputConfiguration
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack (alignment: .leading) {
            Text(placeholder)
                .fontWeight(.thin)
            CTextField(placeholder: placeholder,
                       text: $text,
                       textConfiguration: textInputConfiguration)
            if let errorMessage = errorMessage {
                Label(errorMessage,
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

private struct SectionEditText: View {

    let header: String
    @Binding var text: String
    let textInputConfiguration: TextInputConfiguration

    init(header: String,
         text: Binding<String>,
         textInputConfiguration: TextInputConfiguration = .url)
    {
        self.header = header
        self._text = text
        self.textInputConfiguration = textInputConfiguration
    }

    var body: some View {
        Section(header: Text(header)) {
            CTextField(placeholder: header,
                       text: $text,
                       textConfiguration: textInputConfiguration)
        }
    }
}

private struct FetchButton: View {
    let text: String
    var isLoading: Bool
    var buttonAction: () -> Void

    var body: some View {
        Button(action: buttonAction, label: {
            HStack {
                Text(text)
                    .padding(.trailing, 10)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
        })
        .disabled(isLoading)
    }
}

private extension Date {

    var dateFormatted: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: self)
    }
}
