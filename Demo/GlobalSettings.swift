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

import Foundation

class GlobalSettings: ObservableObject {
    enum Keys {
        static var clientId = "clientId"
        static var baseUrl = "baseUrl"
        static var tokenEndpointPath = "tokenEndpointPath"
        static var authorizationEndpointPath = "authorizationEndpointPath"
        static var followRedirects = "followRedirects"
        static var automaticPolling = "automaticPolling"
    }
    
    @Published var clientId: String {
        didSet {
            UserDefaults.standard.set(clientId, forKey: Keys.clientId)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var baseUrl: String {
        didSet {
            UserDefaults.standard.set(baseUrl, forKey: Keys.baseUrl)
            UserDefaults.standard.synchronize()
        }
    }
    
    @Published var tokenEndpointPath: String {
        didSet {
            UserDefaults.standard.set(tokenEndpointPath, forKey: Keys.tokenEndpointPath)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var authorizationEndpointPath: String {
        didSet {
            UserDefaults.standard.set(authorizationEndpointPath, forKey: Keys.authorizationEndpointPath)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var followRedirects: Bool {
        didSet {
            UserDefaults.standard.set(followRedirects, forKey: Keys.followRedirects)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var automaticPolling: Bool {
        didSet {
            UserDefaults.standard.set(automaticPolling, forKey: Keys.automaticPolling)
            UserDefaults.standard.synchronize()
        }
    }

    init() {
        clientId = UserDefaults.standard.string(forKey: Keys.clientId) ?? "haapi-ios-dev-client"
        baseUrl = UserDefaults.standard.string(forKey: Keys.baseUrl) ?? "https://localhost:8443"
        tokenEndpointPath = UserDefaults.standard.string(forKey: Keys.tokenEndpointPath) ?? "/dev/oauth/token"
        authorizationEndpointPath = UserDefaults.standard.string(forKey: Keys.authorizationEndpointPath) ?? "/dev/oauth/authorize"
        followRedirects = UserDefaults.standard.optionalBool(forKey: Keys.followRedirects) ?? true
        automaticPolling = UserDefaults.standard.optionalBool(forKey: Keys.automaticPolling) ?? true
    }
}
