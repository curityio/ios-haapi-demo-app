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

import Foundation

class ProfileManager: ObservableObject {
    // MARK: Properties

    private let userDefaults: UserDefaults

    @Published private(set) var activeProfile: Profile
    @Published private(set) var profiles: [Profile]

    private enum Constants {
        static let profiles = "profileManager.profiles"
        static let activeProfile = "profileManager.activeProfile"
    }

    // MARK: Init

    init(_ userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        activeProfile = Profile.default
        profiles = []
        load()
        save()
    }

    private func load() {
        if let activeData = userDefaults.value(forKey: Constants.activeProfile) as? Data,
           let savedActive = try? JSONDecoder().decode(Profile.self, from: activeData)
        {
            activeProfile = savedActive
        }

        if let profileData = userDefaults.value(forKey: Constants.profiles) as? Data,
           let savedProfiles = try? JSONDecoder().decode([Profile].self, from: profileData)
        {
            profiles = savedProfiles
        } else {
            profiles = []
        }
    }

    private func save() {
        do {
            let profilesData = try JSONEncoder().encode(profiles)
            let activeProfileData = try JSONEncoder().encode(activeProfile)
            userDefaults.setValue(profilesData, forKey: Constants.profiles)
            userDefaults.setValue(activeProfileData, forKey: Constants.activeProfile)
        } catch  {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: APIs

    lazy var haapiRedirectURI: String? = {
        guard let redirectURI = Bundle.main.haapiRedirectURI else { return nil }

        return redirectURI
    }()

    func addNewProfile() {
        profiles.append(Profile.newProfile(profiles.count + 1))

        save()
    }

    func update(_ profile: Profile,
                at index: Int)
    {
        guard index >= 0, index < profiles.count else { return }
        profiles[index] = profile

        save()
    }

    func updateActiveProfile(_ profile: Profile) {
        activeProfile = profile

        save()
    }

    func remove(at offset: IndexSet) {
        profiles.remove(atOffsets: offset)

        save()
    }

    @discardableResult
    func apply(_ profile: Profile) -> Bool {
        guard let indexFound = profiles.firstIndex(of: profile) else {
            return false
        }
        profiles.remove(at: indexFound)
        profiles.append(activeProfile)
        activeProfile = profile

        save()
        return true
    }

    // MARK: Makers

    func makeProfileView(for profile: Profile) -> ProfileView? {
        let profileView: ProfileView?
        if activeProfile == profile {
            profileView = ProfileView(viewModel: ProfileViewModel(profile,
                                                                  profileManager: self))
        } else {
            if let idxProfile = profiles.firstIndex(of: profile) {
                profileView = ProfileView(viewModel: IndexedProfileViewModel(profile,
                                                                             at: idxProfile,
                                                                             profileManager: self))
            } else {
                profileView = nil
            }
        }

        return profileView
    }

    func makeProfilViewForNewProfile() -> ProfileView? {
        guard let newProfile = profiles.last else {
            return nil
        }
        let index = profiles.count - 1
        return ProfileView(viewModel: IndexedProfileViewModel(newProfile,
                                                              at: index,
                                                              profileManager: self))
    }
}
