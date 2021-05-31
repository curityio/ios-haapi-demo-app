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

import XCTest
@testable import IdsvrHaapiSdkDemo

class ProfileManagerTests: XCTestCase {

    private var profileManager: ProfileManager!
    let suiteName = "TEST"

    override func setUp() {
        super.setUp()

        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        profileManager = ProfileManager(userDefaults)
    }

    func testAddNewProfile() {
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty at the beginning")
        profileManager.addNewProfile()
        XCTAssertFalse(profileManager.profiles.isEmpty, "Profiles should not be empty after calling addNewProfile")
    }

    func testUpdateAProfileAtIndex() {
        let fakeProfile = Profile.default
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty")
        profileManager.update(fakeProfile, at: -100)
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty")
        profileManager.update(fakeProfile, at: 100)
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty")
        profileManager.update(fakeProfile, at: 0)
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty")

        profileManager.addNewProfile()
        var newProfile = profileManager.profiles.first!
        let testValue = "Test"
        XCTAssertNotEqual(newProfile.clientId, testValue, "Profile.clientId should not match \(testValue)")
        newProfile.clientId = testValue
        profileManager.update(newProfile, at: 0)
        let latestFirstProfile = profileManager.profiles.first!
        XCTAssertEqual(latestFirstProfile.clientId, testValue, "Profile.clientId should match \(testValue)")
    }

    func testUpdateActiveProfile() {
        var activeProfile = profileManager.activeProfile
        XCTAssertEqual(activeProfile, profileManager.activeProfile, "activeProfile and profileManager.activeProfile should be equal")
        activeProfile.clientId = "Test"
        XCTAssertNotEqual(activeProfile, profileManager.activeProfile, "activeProfile and profileManager.activeProfile should NOT be equal")

        profileManager.updateActiveProfile(activeProfile)
        XCTAssertEqual(activeProfile, profileManager.activeProfile, "activeProfile and profileManager.activeProfile should be equal")
    }

    func testRemoveProfileAtOffset() {
        profileManager.addNewProfile()
        let profile0 = profileManager.profiles.first!
        profileManager.addNewProfile()
        profileManager.addNewProfile()
        XCTAssertEqual(profileManager.profiles.count, 3, "ProfileManager.profiles should have 3 elements")
        XCTAssertTrue(profileManager.profiles.contains(profile0), "ProfileManager.profile should contain profile0: \(profile0)")

        profileManager.remove(at: IndexSet(integer: 0))
        XCTAssertNotEqual(profileManager.profiles.count, 3, "ProfileManager.profiles should NOT have 3 elements")
        XCTAssertFalse(profileManager.profiles.contains(profile0), "ProfileManager.profile should NOT contain profile0: \(profile0)")
    }

    func testApplyProfileAsActive() {
        let oldProfile = profileManager.activeProfile

        let rogueProfile = Profile.default

        XCTAssertFalse(profileManager.apply(rogueProfile), "Cannot apply rogue Profile")
        XCTAssertTrue(profileManager.profiles.isEmpty, "Profiles should be empty")
        XCTAssertNotEqual(rogueProfile, profileManager.activeProfile, "rogueProfile and ProfileManager.activeProfile should NOT be the same")

        profileManager.addNewProfile()

        let legitProfile = profileManager.profiles.first!
        profileManager.apply(legitProfile)
        XCTAssertEqual(legitProfile, profileManager.activeProfile, "legitProfile should be the Active Profile")
        XCTAssertTrue(profileManager.profiles.contains(oldProfile), "ProfileManager.profiles should contain \(oldProfile)")
    }

    func testMakeProfileView() {
        let invalidProfile = Profile.default
        XCTAssertNil(profileManager.makeProfileView(for: invalidProfile), "Should not return a ProfileView with an unregistered Profile")
        XCTAssertNotNil(profileManager.makeProfileView(for: profileManager.activeProfile), "Should return a ProfileView with an activeProfile")

        profileManager.addNewProfile()
        let newProfile = profileManager.profiles.last!
        XCTAssertNotNil(profileManager.makeProfileView(for: newProfile), "Should return a ProfileView with a new Profile")
    }

    func testMakeProfileViewForNewProfile() {
        XCTAssertNil(profileManager.makeProfilViewForNewProfile(), "Should not return a view because a profile was not created")
        profileManager.addNewProfile()
        XCTAssertNotNil(profileManager.makeProfilViewForNewProfile(), "Should return a view after addNewProfile")
    }


}
