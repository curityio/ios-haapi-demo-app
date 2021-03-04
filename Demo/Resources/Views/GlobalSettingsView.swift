/*
 * Copyright (C) 2020 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import SwiftUI

struct GlobalSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settings: GlobalSettings

    @State var hasLoaded = false
    @State var baseUrlText = ""
    @State var showingErrorAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Redirect URI")) {
                    Text(Constants.redirectUri)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Client ID")) {
                    TextFieldRow(
                        placeholder: "Enter a client ID",
                        textFieldText: $settings.clientId
                    )
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                }
                
                Section(header: Text("Base url")) {
                    TextFieldRow(
                        placeholder: "Enter an url",
                        textFieldText: $baseUrlText,
                        didEndFocusAction: baseUrlTextFieldDidEndFocus
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                
                Section(header: Text("Token endpoint path")) {
                    TextFieldRow(
                        placeholder: "Enter a path",
                        textFieldText: $settings.tokenEndpointPath
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                
                Section(header: Text("Authorization endpoint path")) {
                    TextFieldRow(
                        placeholder: "Enter a path",
                        textFieldText: $settings.authorizationEndpointPath
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                
                Section {
                    ToggleRow(title: "Follow redirects", isOnValue: $settings.followRedirects)
                    ToggleRow(title: "Automatic polling", isOnValue: $settings.automaticPolling)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if !hasLoaded {
                    baseUrlText = settings.baseUrl
                }
                hasLoaded = true
            }
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error in base url"),
                    message: Text("Enter a valid base url"),
                    dismissButton: .default(Text("Ok"))
                )
            }
        }
    }

    private func baseUrlTextFieldDidEndFocus() {
        if let url = URL(string: baseUrlText),
           UIApplication.shared.canOpenURL(url) {
            settings.baseUrl = baseUrlText
        } else {
            showingErrorAlert = true
        }
    }
}

struct TextFieldRow: View {
    var placeholder: String
    @Binding var textFieldText: String
    var didEndFocusAction: () -> Void = {}

    var body: some View {
        HStack {
            TextField(placeholder, text: $textFieldText, onEditingChanged: { editingChanged in
                if !editingChanged {
                    didEndFocusAction()
                }
            })
        }
    }
}

struct ToggleRow: View {
    var title: String
    @Binding var isOnValue: Bool

    var body: some View {
        HStack {
            Toggle(title, isOn: $isOnValue)
        }
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSettingsView()
    }
}
