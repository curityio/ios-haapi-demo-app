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

import Foundation
import IdsvrHaapiSdk
import os
import Combine

typealias HaapiCompletionHandler = (HaapiState) -> Void

class HaapiController: ObservableObject {

    static let stateNotification = NSNotification.Name("haapiController.stateNotification")

    // MARK: Properties

    @Published private(set) var state = HaapiState.none {
        didSet {
            notificationCenter.post(name: Self.stateNotification,
                                    object: state,
                                    userInfo: nil)
        }
    }

    private let notificationCenter: NotificationCenter
    private(set) var isProcessing = false
    private var clientOperation: ClientOperation?

    private(set) var profile: Profile?
    private var haapiTokenManager: HaapiTokenManager?
    private var haapiClient: HaapiClient?
    private var getAccessTokenPublisher: AnyCancellable?

    init(_ notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }
}

// MARK: - Public APIs for HaapiController

extension HaapiController: HaapiControllable {

    func start(with profile: Profile,
               completionHandler: HaapiCompletionHandler? = nil)
    {
        guard !isProcessing else {
            Logger.controllerFlow.error("The call is ignored because a start() was already triggered.")
            return
        }

        isProcessing = true
        self.profile = profile
        do {
            try initializeTokenManager(for: profile)
        } catch {
            commitState(.systemError(error),
                        completionHandler: completionHandler)
            return
        }
        Logger.controllerFlow.info("Starting HAAPI flow")

        let configuration = URLSessionConfiguration.haapiFlow
        let session = URLSession(configuration: configuration,
                                 delegate: profile.isDefaultAuthChallengeEnabled ? nil : TrustAllCertsDelegate(),
                                 delegateQueue: nil)

        haapiClient = haapiTokenManager?.createClient(urlSession: session)

        guard let authorizationUrl = profile.authorizationURL else {
            commitState(.systemError(HaapiControllerError.invalidUrl),
                        completionHandler: completionHandler)
            return
        }

        var request = URLRequest(url: authorizationUrl)
        request.httpMethod = "GET"

        haapiClient?.performDataTask(for: request) { result in
            do {
                switch result {
                case .success(let responseAndData):
                    guard let httpResponse = responseAndData.response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                        let statusCode = (responseAndData.response as? HTTPURLResponse)?.statusCode ?? 0
                        throw HaapiControllerError.serverError(statusCode: statusCode)
                    }

                    guard let data = responseAndData.data else {
                        throw HaapiControllerError.noResponseData
                    }

                    let representation = try Representation(data)
                    if profile.followRedirects,
                       let redirectionStep = RedirectionStep(representation) {
                        Logger.controllerFlow.debug("Following redirect")
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.submitForm(form: redirectionStep.redirectForm,
                                             completionHandler: completionHandler)
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            self?.commitState(.next(HaapiStateContent(representation: representation,
                                                                      continueActions: representation.actions)),
                                              completionHandler: completionHandler)
                        }
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.commitState(.systemError(error),
                                      completionHandler: completionHandler)
                }
            }
        }
    }

    func reset() {
        Logger.controllerFlow.info("Resetting HAAPI flow")
        isProcessing = false
        clientOperation = nil
        profile = nil
        haapiTokenManager?.close()
        haapiTokenManager = nil
        haapiClient = nil
        getAccessTokenPublisher?.cancel()
        getAccessTokenPublisher = nil
        commitState(.none, completionHandler: nil)
    }

    func submitForm(
        form: FormModel,
        parameterOverrides: [String: String] = [:],
        completionHandler: HaapiCompletionHandler? = nil
    ) {
        isProcessing = true

        guard let profile = profile else {
            assertionFailure("Programming error: profile should not be empty")
            commitState(.systemError(HaapiControllerError.incorrectReset),
                        completionHandler: completionHandler)
            return
        }

        do {
            let url = try profile.urlRelativeToBaseURL(href: form.href)
            let formParameters = curateFormParameters(form: form, parameterOverrides: parameterOverrides)
            var request: URLRequest

            if form.method == "GET" {
                if let urlForRequest = url.withQuery(parameters: formParameters) {
                    request = URLRequest(url: urlForRequest)
                } else {
                    throw HaapiControllerError.invalidUrl
                }
            } else {
                request = URLRequest(url: url)
                request.httpBody = formParameters.httpBody
            }

            request.httpMethod = form.method

            Logger.controllerFlow.info("Submitting HAAPI Form; url=\(url.absoluteString), parameters=\(formParameters)")
            callHaapi(
                request: request,
                continueActions: form.continueActions,
                completionHandler: completionHandler
            )
        } catch {
            commitState(.systemError(error),
                        completionHandler: completionHandler)
        }
    }

    func getAccessToken(_ code: String,
                        completionHandler: HaapiCompletionHandler?)
    {
        isProcessing = true

        guard let profile = profile,
              let redirectURI = Bundle.main.haapiRedirectURI
        else {
            fatalError("Profile should not be empty at this stage")
        }
        var urlComponents = URLComponents()
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: profile.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code)
        ]

        guard let url = urlComponents.url(relativeTo: URL(string: profile.tokenEndpointURI)),
              url.isHttpURL
        else {
            commitState(.systemError(HaapiControllerError.invalidUrl), completionHandler: completionHandler)
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.httpMethod = "POST"
        request.httpBody = urlComponents.query?.data(using: .utf8)
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config, delegate: TrustAllCertsDelegate(), delegateQueue: nil)

        getAccessTokenPublisher = session.dataTaskPublisher(for: request)
            .mapError{ error -> HaapiControllerError in
                return HaapiControllerError.general(cause: error)
            }
            .tryMap{ (data: Data, _) -> Data in
                Logger.controllerFlow.debug("Representation received: \(String(data: data, encoding: .utf8) ?? "-")")
                return data
            }
            .decode(type: TokensRepresentation.self, decoder: JSONDecoder())
            .mapError { error -> HaapiControllerError in
                return HaapiControllerError.general(cause: error)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completions in
                    self?.getAccessTokenPublisher = nil

                    switch completions {
                    case .failure(let error):
                        self?.commitState(.systemError(error),
                                          completionHandler: completionHandler)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] tokenRepresentation in
                    self?.commitState(.accessToken(tokenRepresentation),
                                      completionHandler: completionHandler)
                }
            )
    }

    func followLink(link: Link,
                    completionHandler: HaapiCompletionHandler? = nil)
    {
        isProcessing = true

        guard let profile = profile else {
            assertionFailure("Programming error: profile should not be empty")
            return
        }

        do {
            let url = try profile.urlRelativeToBaseURL(href: link.href)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            Logger.controllerFlow.info("Getting HAAPI Link; url=\(url.absoluteString)")
            callHaapi(
                request: request,
                continueActions: [],
                completionHandler: completionHandler
            )
        } catch {
            commitState(.systemError(error),
                        completionHandler: completionHandler)
        }
    }

    func handleContinueActions(continueActions: [Action],
                               completionHandler: HaapiCompletionHandler? = nil)
    {
        isProcessing = true

        do {
            if true == profile?.followRedirects,
               continueActions.count == 1,
               let action = continueActions.first,
               let redirectionStep = RedirectionStep(action)
            {
                Logger.controllerFlow.debug("Following redirect")

                submitForm(form: redirectionStep.redirectForm,
                           completionHandler: completionHandler)
            } else {
                try commitContinueState(continueActions: continueActions,
                                        completionHandler: completionHandler)
            }
        } catch {
            commitState(.systemError(error),
                        completionHandler: completionHandler)
        }
    }

    func handleURL(_ url: URL) {
        clientOperation?.continueOperation(url: url, haapiSubmiter: self)
    }
}

// MARK: Private functions of HaapiController

extension HaapiController {

    private func initializeTokenManager(for profile: Profile) throws {
        assert(nil == haapiTokenManager, "HaapiTokenManager should not exist, there is something wrong in the flow")
        guard let tokenUrl = URL(string: profile.tokenEndpointURI), tokenUrl.isHttpURL else {
            throw HaapiControllerError.invalidUrl
        }

        let configuration = URLSessionConfiguration.haapiFlow
        let authenticationChallengeHandler = profile.isDefaultAuthChallengeEnabled ? nil : TrustAllCertsDelegate()
        let urlSession = URLSession(configuration: configuration,
                                    delegate: authenticationChallengeHandler,
                                    delegateQueue: nil)

        let haapiTokenManager = HaapiTokenManagerBuilder(
            tokenEndpoint: tokenUrl,
            clientId: profile.clientId
        )
            .setInternalUrlSession(urlSession)
            .build()
        self.haapiTokenManager = haapiTokenManager
    }
    
    private func commitContinueState(continueActions: [Action],
                                     completionHandler: HaapiCompletionHandler?) throws
    {
        if case .next(let content) = state {
            let newContent = HaapiStateContent(representation: content.representation,
                                               continueActions: continueActions)
            clientOperation = ClientOperationManager.makeForActions(continueActions)
            commitState(.next(newContent), completionHandler: nil)
        } else {
            assertionFailure("Not possible to handle gracefully")
            throw HaapiControllerError.noCurrentState
        }
    }
    
    private func commitState(_ state: HaapiState,
                             completionHandler: HaapiCompletionHandler?)
    {
        clientOperation?.startOperation(haapiRedirect: self,
                                        onCompletion:
        { remainInTransitioningState in
            if !remainInTransitioningState {
                self.isProcessing = false
            }
        })

        isProcessing = false
        Logger.controllerFlow.debug("Commit state: \(state)")
        completionHandler?(state)
        if self.state != state {
            self.state = state
        }
    }

    private func callHaapi(request: URLRequest,
                           continueActions: [Action],
                           completionHandler: HaapiCompletionHandler?)
    {
        haapiClient?.performDataTask(for: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseAndData):
                    self.onRequestSuccess(responseAndData: responseAndData,
                                          continueActions: continueActions,
                                          completionHandler: completionHandler)
                case .failure(let error):
                    Logger.controllerFlow.error("HaapiClient error for performData: \(error.localizedDescription)")
                    self.commitState(.systemError(error), completionHandler: completionHandler)
                }
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func onRequestSuccess(
        responseAndData: ResponseAndData,
        continueActions: [Action],
        completionHandler: HaapiCompletionHandler?
    ) {
        do {
            guard let httpResponse = responseAndData.response as? HTTPURLResponse,
                httpResponse.statusCode < 500 else {
                let statusCode = (responseAndData.response as? HTTPURLResponse)?.statusCode ?? 0
                throw HaapiControllerError.serverError(statusCode: statusCode)
            }

            guard let data = responseAndData.data else {
                throw HaapiControllerError.noResponseData
            }

            Logger.controllerFlow.debug("Representation received: \(String(data: data, encoding: .utf8) ?? "-")")

            let representation = try Representation(data)
            // Problem, ContinueActions, Polling

            if let problem = ProblemFactory.create(representation) {
                if let authorizationProblem = problem as? AuthorizationProblem,
                   let error = authorizationProblem.error
                {
                    Logger.controllerFlow.debug("AuthorizationProblem detected -> abort")
                    throw error
                }

                Logger.controllerFlow.debug("Will commit problem")

                clientOperation = ClientOperationManager.makeForActions(representation.actions)
                commitState(.problem(problem),
                            completionHandler: completionHandler)
            }
            else if case .continueSameStep = representation.type {
                Logger.controllerFlow.debug("Will commit continue state")

                try commitContinueState(continueActions: continueActions,
                                        completionHandler: completionHandler)
            }
            else if true == profile?.followRedirects {
                if let redirectionStep = RedirectionStep(representation) {
                    Logger.controllerFlow.debug("Following redirect")

                    submitForm(form: redirectionStep.redirectForm,
                               completionHandler: completionHandler)
                }
                else if let pollingStep = PollingStep(representation),
                        let formModel = pollingStep.formModel
                {
                    Logger.controllerFlow.debug("Following polling")
                    // Commit new state -> Polling then keep submitting from the UI
                    if pollingStep.status == .pending {
                        clientOperation = ClientOperationManager.makeForActions(representation.actions)
                        commitState(.polling(pollingStep), completionHandler: completionHandler)
                    } else {
                        submitForm(form: formModel,
                                   completionHandler: completionHandler)
                    }
                }
                else if case .oauthAuthorizationResponse = representation.type,
                        let code = representation.properties["code"]
                {
                    Logger.controllerFlow.debug("Following authorization response")

                    clientOperation = nil
                    getAccessToken(code, completionHandler: completionHandler)
                } else {
                    Logger.controllerFlow.debug("Following display Form")

                    clientOperation = ClientOperationManager.makeForActions(representation.actions)
                    commitState(.next(representation.haapiState),
                                completionHandler: completionHandler)
                }
            }
            else if case .oauthAuthorizationResponse = representation.type,
                    let code = representation.properties["code"]
            {
                Logger.controllerFlow.debug("Will commit authorization response")

                clientOperation = ClientOperationManager.makeForActions(representation.actions)
                commitState(.authorizationResponse(code),
                            completionHandler: completionHandler)
            }
            else if let pollingStep = PollingStep(representation) {
                Logger.controllerFlow.debug("Will commit polling - no redirect")
                // Commit new state -> Polling then keep submitting from the UI
                clientOperation = ClientOperationManager.makeForActions(representation.actions)
                commitState(.polling(pollingStep), completionHandler: completionHandler)
            }
            else {
                Logger.controllerFlow.debug("Will commit representation type: \(representation.type.rawValue)")

                clientOperation = ClientOperationManager.makeForActions(representation.actions)
                commitState(.next(representation.haapiState),
                            completionHandler: completionHandler)
           }
        } catch {
            commitState(.systemError(error),
                        completionHandler: completionHandler)
        }
    }
    
    private func curateFormParameters(form: FormModel, parameterOverrides: [String: String]) -> [String: String] {
        var formParameters = [String: String]()
        var copyParameterOverrides = parameterOverrides
        
        for field in form.fields {
            let name = field.name
            
            if let value = copyParameterOverrides[name] {
                formParameters[name] = value
                copyParameterOverrides[name] = nil
            }
            else if let value = field.value {
                formParameters[name] = value
            }
        }

        if !copyParameterOverrides.isEmpty {
            Logger.controllerFlow.warning("copyParameterOverrides is not empty: \(copyParameterOverrides)")
        }
        
        return formParameters
    }
}

// MARK: - Private helpers

private extension URLSessionConfiguration {

    static var haapiFlow: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20.0
        configuration.timeoutIntervalForResource = 20.0
        configuration.waitsForConnectivity = false

        return configuration
    }
}

private extension Dictionary where Key == String, Value == String {

    var httpBody: Data? {
        guard !isEmpty else {
            return nil
        }

        var body = URLComponents()

        body.queryItems = map { key, value in
            URLQueryItem(name: key, value: value)
        }

        return body.query?.data(using: .utf8)
    }
}

private extension Profile {

    private var processedScope: String? {
        guard let selectedScope = selectedScopes, !selectedScope.isEmpty else { return nil }

        return selectedScope.joined(separator: " ")
    }

    var authorizationURL: URL? {
        guard let redirectURI = Bundle.main.haapiRedirectURI else { return nil }

        var urlComponents = URLComponents()
        var queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]

        if let scope = processedScope {
            queryItems.append(URLQueryItem(name: "scope", value: scope))
        }
        
        urlComponents.queryItems = queryItems

        return urlComponents.url(relativeTo: URL(string: authorizationEndpointURI))
    }

    func urlRelativeToBaseURL(href: String) throws -> URL {
        guard let url = URL(string: href, relativeTo: URL(string: baseURLString)) else {
            throw HaapiControllerError.invalidUrl
        }

        return url
    }
}

private extension Representation {

    var haapiState: HaapiStateContent {
        return HaapiStateContent(representation: self,
                                 continueActions: self.actions)
    }
}
