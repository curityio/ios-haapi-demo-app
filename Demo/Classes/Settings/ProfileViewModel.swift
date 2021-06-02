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
import Combine
import UIKit

class ProfileViewModel: ObservableObject {

    // MARK: Properties

    @Published var profile: Profile {
        didSet {
            update()
        }
    }
    @Published var scopeViewModel: ScopesViewModel?

    fileprivate weak var profileManager: ProfileManager?
    private let urlSession: URLSession

    private var cancellable: AnyCancellable?

    enum ProfileViewModelError: Error {
        case invalidJSON
    }

    // MARK: Init

    init(_ profile: Profile,
         profileManager: ProfileManager,
         urlSession: URLSession = .dev)
    {
        self.profile = profile
        self.profileManager = profileManager
        self.urlSession = urlSession

        updateScopeViewModel()
    }

    fileprivate func update() {
        profileManager?.updateActiveProfile(profile)
    }

    private func updateScopeViewModel() {
        if let supportedScopes = profile.supportedScopes {
            scopeViewModel = ScopesViewModel(supportedScopes,
                                             selectedItems: profile.selectedScopes ?? [],
                                             delegate: self)
        } else {
            scopeViewModel = nil
        }
    }

    // MARK: 'Public'

    func apply() {
        profileManager?.apply(profile)
    }

    var isActiveProfile: Bool {
        return true
    }

    func pullMetaData(completion: @escaping () -> Void) {
        guard let url = profile.metaDataEndpointURL else {
            completion()
            return
        }

        cancellable = urlSession.dataTaskPublisher(for: url)
            .map { $0.data }
            .tryMap { data -> (String, String, [String]) in
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tokenEndpoint = json["token_endpoint"] as? String,
                   let authEndPoint = json["authorization_endpoint"] as? String,
                   let supportedScopes = json["scopes_supported"] as? [String]
                {
                    return (tokenEndpoint, authEndPoint, supportedScopes)
                } else {
                    throw ProfileViewModelError.invalidJSON
                }
            }
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                completion()
            } receiveValue: { [weak self] tuple in
                self?.profile.tokenEndpointURI = tuple.0
                self?.profile.authorizationEndpointURI = tuple.1
                self?.profile.supportedScopes = tuple.2
                self?.profile.fetchedAt = Date()
                self?.update()
                self?.updateScopeViewModel()
            }
    }

    var errorBaseURLString: String? {
        return profile.baseURLString.errorInvalidURL
    }

    var errorTokenEndpointURLString: String? {
        return profile.tokenEndpointURI.errorInvalidURL
    }

    var errorAuthorizationEndpointString: String? {
        return profile.authorizationEndpointURI.errorInvalidURL
    }
}

extension ProfileViewModel: ScopesViewModelDelegate {

    func updateSelectedItems(_ items: [String]) {
        profile.selectedScopes = items
        update()
    }
}

// MARK: - IndexedProfileViewModel

final class IndexedProfileViewModel: ProfileViewModel {

    private let index: Int

    init(_ profile: Profile,
         at index: Int,
         profileManager: ProfileManager,
         urlSession: URLSession = .dev)
    {
        self.index = index
        super.init(profile, profileManager: profileManager, urlSession: urlSession)
    }

    override var isActiveProfile: Bool {
        return false
    }

    override func update() {
        profileManager?.update(profile, at: index)
    }
}

private extension String {

    var errorInvalidURL: String? {
        let result: String?
        if let url = URL(string: self),
           UIApplication.shared.canOpenURL(url)
        {
            result = nil
        } else {
            result = "This URL is invalid"
        }

        return result
    }
}
