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

struct ProfileListView: View {
    // MARK: Properties

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private(set) var profileManager: ProfileManager
    @State private var newProfile = false

    private enum Constants {
        static let warningSchemeMissing = "URL scheme was not configured. The demo will not work. \n"
                                            + "Please configure it in the info.plist"
        static let infoScheme = "Please configure this redirect URI in the identity server"
    }

    // MARK: View

    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                Group {
                    Text("Redirect URI")
                        .bold()
                        .padding([.bottom], 8)
                    if let scheme = profileManager.haapiRedirectURI {
                        Text(scheme)
                            .padding([.bottom], 8)
                        Label(Constants.infoScheme,
                              systemImage: "info.circle")
                            .foregroundColor(.blue)
                    } else {
                        Label(Constants.warningSchemeMissing,
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding([.leading, .trailing])

                List {
                    Section(header: Text("Active profile")) {
                        let profile = profileManager.activeProfile
                        NavigationLink(profile.name,
                                       destination: profileManager.makeProfileView(for: profile))
                    }

                    Section(header: Text("Other profiles")) {
                        ForEach(profileManager.profiles, id: \.self) { profile in
                            NavigationLink(profile.name,
                                           destination: profileManager.makeProfileView(for: profile))
                        }
                        .onDelete(perform: { indexSet in
                            profileManager.remove(at: indexSet)
                        })
                    }
                }
                .navigationBarTitle(Text("Profiles"))
                .navigationBarItems(trailing: Button(action: add, label: {
                    BarItemImage(systemName: "plus",
                                 isLeading: false)
                        .accentColor(.primary)
                }))

                // Hidden Link
                NavigationLink(
                    destination: openNewProfile(),
                    isActive: $newProfile,
                    label: {
                        EmptyView()
                    })
                    .hidden()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private extension ProfileListView {

    func add() {
        precondition(!newProfile, "New Profile should be false when add is called")
        profileManager.addNewProfile()
        newProfile = true
    }

    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

    func openNewProfile() -> some View {
        profileManager.makeProfilViewForNewProfile()
            .onDisappear(perform: {
                newProfile = false
            })
    }
}

struct ProfileListView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileListView(profileManager: ProfileManager())
    }
}
