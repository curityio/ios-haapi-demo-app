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

class ProfileViewModelTests: XCTestCase {

    private var profileManager: ProfileManager!
    let suiteName = "TEST"

    override func setUp() {
        super.setUp()

        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        profileManager = ProfileManager(userDefaults)
    }

    // MARK: - ProfileView

    func testProfileViewModelApplyOk() {
        profileManager.addNewProfile()
        let newProfile = profileManager.profiles.last!

        XCTAssertNotEqual(newProfile, profileManager.activeProfile, "newProfile should not be equal to profileManager.activeProfile")
        let viewModel = ProfileViewModel(newProfile, profileManager: profileManager)
        viewModel.apply()
        XCTAssertEqual(newProfile, profileManager.activeProfile, "newProfile should be equal to profileManager.activeProfile")
    }

    func testProfileViewModelApplyIncorrect() {
        let aProfile = Profile.default
        XCTAssertNotEqual(aProfile, profileManager.activeProfile, "aProfile should not be equal to profileManager.activeProfile")
        let viewModel = ProfileViewModel(aProfile, profileManager: profileManager)
        viewModel.apply()
        XCTAssertNotEqual(aProfile, profileManager.activeProfile, "aProfile should not be equal to profileManager.activeProfile")
    }

    func testProfileViewModelIsActiveProfile() {
        let activeProfile = profileManager.activeProfile
        let viewModel = ProfileViewModel(activeProfile, profileManager: profileManager)
        XCTAssertTrue(viewModel.isActiveProfile)
    }

    func testProfileViewModelPullMetaDataOk() {
        let activeProfile = profileManager.activeProfile
        let mockSession: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockPullingMetaDataURLProtocol.self]
            URLProtocol.registerClass(MockPullingMetaDataURLProtocol.self)
            MockPullingMetaDataURLProtocol.testURLS = [activeProfile.metaDataEndpointURL: dataForFileName("metaDataResponse")]
            return URLSession(configuration: config)
        }()
        let viewModel = ProfileViewModel(activeProfile,
                                         profileManager: profileManager,
                                         urlSession: mockSession)
        let resultTokenEndpoint = "TokenEndpoint"
        let resultAuthEndpoint = "AuthEndpoint"
        let resultScopes = ["MyScope"]
        XCTAssertNotEqual(resultTokenEndpoint, activeProfile.tokenEndpointURI, "activeProfile.tokenEndpointPath should not match resultTokenEndpoint")
        XCTAssertNotEqual(resultAuthEndpoint, activeProfile.authorizationEndpointURI, "activeProfile.authorizationEndpointURI should not match resultAuthEndpoint")
        XCTAssertNotEqual(resultScopes, activeProfile.supportedScopes, "activeProfile.supportedScopes should not match resultScopes")

        let exp = expectation(description: "Pulling meta data")
        XCTAssertNil(activeProfile.fetchedAt, "fetchedAt should be nil")

        viewModel.pullMetaData {
            XCTAssertEqual(resultTokenEndpoint, self.profileManager.activeProfile.tokenEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
            XCTAssertEqual(resultAuthEndpoint, self.profileManager.activeProfile.authorizationEndpointURI, "activeProfile.authorizationEndpointURI should match resultAuthEndpoint")
            XCTAssertEqual(resultScopes, self.profileManager.activeProfile.supportedScopes, "activeProfile.supportedScopes should match resultScopes")
            XCTAssertNotNil(self.profileManager.activeProfile.fetchedAt, "fetchedAt should not be nil")

            exp.fulfill()
        }

        wait(for: [exp], timeout: 4)
    }

    func testProfileViewModelPullMetaDataIncorrectURL() {
        var activeProfile = profileManager.activeProfile
        activeProfile.metaDataBaseURLString = "HelloWorld"
        profileManager.updateActiveProfile(activeProfile)
        let viewModel = ProfileViewModel(activeProfile, profileManager: profileManager)
        let resultTokenEndpoint = activeProfile.tokenEndpointURI
        let resultAuthEndpoint = activeProfile.authorizationEndpointURI

        let exp = expectation(description: "Pulling meta data")
        XCTAssertNil(activeProfile.fetchedAt, "fetchedAt should be nil")

        viewModel.pullMetaData {
            XCTAssertEqual(resultTokenEndpoint, self.profileManager.activeProfile.tokenEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
            XCTAssertEqual(resultAuthEndpoint, self.profileManager.activeProfile.authorizationEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
            XCTAssertNil(self.profileManager.activeProfile.fetchedAt, "fetchedAt should be nil")

            exp.fulfill()
        }

        wait(for: [exp], timeout: 4)
    }

    func testProfileViewModelPullMetaDataInvalidJSON() {
        let activeProfile = profileManager.activeProfile
        let mockSession: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockPullingMetaDataURLProtocol.self]
            URLProtocol.registerClass(MockPullingMetaDataURLProtocol.self)
            MockPullingMetaDataURLProtocol.testURLS = [activeProfile.metaDataEndpointURL: dataForFileName("fieldValid")]
            return URLSession(configuration: config)
        }()
        let viewModel = ProfileViewModel(activeProfile,
                                         profileManager: profileManager,
                                         urlSession: mockSession)
        let resultTokenEndpoint = activeProfile.tokenEndpointURI
        let resultAuthEndpoint = activeProfile.authorizationEndpointURI
        XCTAssertEqual(resultTokenEndpoint, activeProfile.tokenEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
        XCTAssertEqual(resultAuthEndpoint, activeProfile.authorizationEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")

        let exp = expectation(description: "Pulling meta data")
        XCTAssertNil(activeProfile.fetchedAt, "fetchedAt should be nil")

        viewModel.pullMetaData {
            XCTAssertEqual(resultTokenEndpoint, self.profileManager.activeProfile.tokenEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
            XCTAssertEqual(resultAuthEndpoint, self.profileManager.activeProfile.authorizationEndpointURI, "activeProfile.tokenEndpointPath should match resultTokenEndpoint")
            XCTAssertNil(self.profileManager.activeProfile.fetchedAt, "fetchedAt should be nil")

            exp.fulfill()
        }

        wait(for: [exp], timeout: 4)
    }

    // MARK: - IndexedProfileViewModel

    func testIndexedProfileViewModelIsActive() {
        let indexedProfile = IndexedProfileViewModel(Profile.default, at: 0, profileManager: profileManager)
        XCTAssertFalse(indexedProfile.isActiveProfile, "indexedProfile should not be 'active;")
    }

}

// MARK: - MockPullingMetaDataURLProtocol

private class MockPullingMetaDataURLProtocol: URLProtocol {

    static var testURLS = [URL?: Data]()

    enum MockError: Error {
        case developerError
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let data = Self.testURLS[request.url] {
            client?.urlProtocol(self, didReceive: request.url!.httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        } else {
            client?.urlProtocol(self, didFailWithError: MockError.developerError)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

// MARK: - Private helpers

private extension URL {

    var httpResponse: HTTPURLResponse {
        return HTTPURLResponse(url: self, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

}

private func dataForFileName(_ fileName: String, withExtensionType type: String = ".json") -> Data {
    let url = Bundle(for: ProfileViewModelTests.self).url(forResource: fileName, withExtension: type)
    return try! Data(contentsOf: url!)
}
