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
import IdsvrHaapiSdk
import os

private let logger = Logger()

typealias OnCommitState = (HaapiState?) -> Void
typealias OnError = (Error) -> Void

enum HaapiControllerErrors: Error {
    case invalidUrl
    case general(cause: Error)
    case noResponseData
    case serverError(statusCode: Int)
    case noCurrentState
    case problem(problem: Problem)
    case illegalState(message: String)
}

struct HaapiState {
    var problem: Problem?
    let representation: Representation
    let continueActions: [Action]?
    let clientOperation: ClientOperation?
    // TODO : add continueMessages to replace previous Representation's messages
    
    init(
        representation: Representation,
        continueActions: [Action]? = nil,
        clientOperation: ClientOperation? = nil,
        problem: Problem? = nil
    ) {
        self.representation = representation
        self.continueActions = continueActions
        self.clientOperation = clientOperation
        self.problem = problem
    }
    
    var currentActions: [Action] {
        continueActions ?? representation.actions
    }
}

/// This base class is a "no operation" implementation, useful for abstraction in views and for ViewPreview implementations;
/// RuntimeHaapiController should be used at runtime.
class HaapiController: ObservableObject {
    @Published fileprivate(set) var currentState: HaapiState?
    @Published var transitioning: Bool
    @Published var textFieldTextStates: [TextState] = []
    @Published var toggleFieldStates: [BoolState] = []
    @Published var displayingErrorMessage: String = ""
    @Published var isDisplayingErrorDialog: Bool = false
    
    /// Available for debugging purposes
    init(currentState: HaapiState? = nil, transitioning: Bool = false) {
        self.currentState = currentState
        self.transitioning = transitioning
    }
    
    func reset() {
        logNoop()
    }
    
    func submitForm(
        form: FormModel,
        parameterOverrides: [String: String] = [:],
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        logNoop()
    }

    func followLink(
        link: Link,
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        logNoop()
    }
    
    func handleContinueActions(
        continueActions: [Action],
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        logNoop()
    }
    
    private func logNoop() {
        logger.warning("No-op HaapiController, use RuntimeHaapiController instead.")
    }

    func showErrorDialog(withMessage message: String) {
        isDisplayingErrorDialog = true
        displayingErrorMessage = message
    }
}

class RuntimeHaapiController: HaapiController {
    private var haapiTokenManager: HaapiTokenManager
    
    private var haapiClient: HaapiClient?
    private var globalSettings: GlobalSettings

    init(
        globalSettings: GlobalSettings,
        followRedirects: Bool = true
    ) throws {
        self.globalSettings = globalSettings
        self.haapiTokenManager = try Self.makeTokenManager(globalSettings: globalSettings)
    }

    func resetFromGlobalSettings() {
        do {
            haapiTokenManager.close()
            self.haapiTokenManager = try Self.makeTokenManager(globalSettings: self.globalSettings)
        } catch {
            logger.error("Error in resetFromGlobalSettings: \(error.localizedDescription)")
        }
    }

    private static func makeTokenManager(globalSettings: GlobalSettings) throws -> HaapiTokenManager {
        guard let baseUrl = URL(string: globalSettings.baseUrl),
              let tokenUrl = URL(string: globalSettings.tokenEndpointPath, relativeTo: baseUrl) else {
            throw HaapiControllerErrors.invalidUrl
        }
        
        let configuration = makeUrlSessionConfiguration()
        let trustAllCertsDelegate = TrustAllCertsDelegate()
        let urlSession = URLSession(configuration: configuration, delegate: trustAllCertsDelegate, delegateQueue: nil)
        
        let haapiTokenManager = HaapiTokenManager.Builder(
            tokenEndpoint: tokenUrl,
            clientId: globalSettings.clientId
        )
            .setInternalUrlSession(urlSession)
            .build()
        return haapiTokenManager
    }
    
    private static func makeUrlSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20.0
        configuration.timeoutIntervalForResource = 20.0
        configuration.waitsForConnectivity = false
        
        return configuration
    }

    private var authorizationUrl: URL? {
        guard let baseUrl = URL(string: globalSettings.baseUrl) else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.path = globalSettings.authorizationEndpointPath
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: globalSettings.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectUri)
        ]
        
        return urlComponents.url(relativeTo: baseUrl)
    }
    
    private func commitProblemState(
        problem: Problem,
        representation: Representation,
        willCommitState: @escaping OnCommitState
    ) {
        let newState: HaapiState
        
        let displayProblemOnSameView: Bool
        if case .invalidInputProblem = problem.representation.type {
            displayProblemOnSameView = true
        } else if case .incorrectCredentialsProblem = problem.representation.type {
            displayProblemOnSameView = true
        } else {
            displayProblemOnSameView = false
        }
        
        if displayProblemOnSameView,
           let currentState = self.currentState {
            newState = HaapiState(
                representation: currentState.representation,
                continueActions: currentState.continueActions,
                clientOperation: ClientOperationManager.makeForActions(problem.representation.actions),
                problem: problem
            )
        } else {
            newState = HaapiState(
                representation: representation
            )
        }
        
        self.commitState(newState, willCommitState: willCommitState, clearFieldStateCaches: false)
    }
    
    private func commitContinueState(
        continueActions: [Action],
        willCommitState: @escaping OnCommitState
    ) throws {
        guard let currentRepresentation = self.currentState?.representation else {
            throw HaapiControllerErrors.noCurrentState
        }

        self.commitState(
            HaapiState(
                representation: currentRepresentation,
                continueActions: continueActions,
                clientOperation: ClientOperationManager.makeForActions(continueActions)
            ),
            clearFieldStateCaches: true
        )
    }
    
    private func commitState(
        representation: Representation,
        willCommitState: OnCommitState? = nil,
        clearFieldStateCaches: Bool
    ) {
        commitState(
            HaapiState(
                representation: representation,
                clientOperation: ClientOperationManager.makeForActions(representation.actions)
            ),
            willCommitState: willCommitState,
            clearFieldStateCaches: clearFieldStateCaches
        )
    }
    
    private func commitState(
        _ state: HaapiState?,
        willCommitState: OnCommitState? = nil,
        clearFieldStateCaches: Bool
    ) {
        DispatchQueue.main.async {
            let oldTextFieldStatesIds = self.textFieldTextStates.map { $0.textFieldId }
            let oldToggleFieldStatesIds = self.toggleFieldStates.map { $0.fieldId }
            willCommitState?(state)
            self.currentState = state
            
            if clearFieldStateCaches {
                // Clear up cache a bit after the UI has redrawn. No rush.
                performBlock({
                    self.textFieldTextStates.removeAll(
                        where: { oldTextFieldStatesIds.contains($0.textFieldId) }
                    )
                    self.toggleFieldStates.removeAll(
                        where: { oldToggleFieldStatesIds.contains($0.fieldId) }
                    )
                }, afterDelay: 0.2)
            }
            
            if let clientOperation = state?.clientOperation {
                // If there is an active client-operation, we remain in a transitioning state until it completes,
                // the call to handleContinueActions will update the transitioning state as appropriate.
                clientOperation.startOperation(haapiController: self) { remainInTransitioningState in
                    if !remainInTransitioningState {
                        self.transitioning = false
                    }
                }
            } else {
                self.transitioning = false
            }
        }
    }
    
    private func startTransition() {
        DispatchQueue.main.async {
            self.transitioning = true
        }
    }
    
    private func handleError(_ error: Error, withOnErrorCallback onError: @escaping OnError) {
        logger.error("Error: \(String(describing: error))")
        
        DispatchQueue.main.async {
            onError(error)
            self.transitioning = false
            self.showErrorDialog(withMessage: String(describing: error))
        }
    }
    
    // FIXME: Do we need the OnError callback?
    func start(onError: @escaping OnError, willCommitState: @escaping OnCommitState) {
        resetFromGlobalSettings()
        logger.info("Starting HAAPI flow")
        commitState(nil, clearFieldStateCaches: false)
        startTransition()
        
        let configuration = RuntimeHaapiController.makeUrlSessionConfiguration()
        let session = URLSession(configuration: configuration,
                                 delegate: TrustAllCertsDelegate(),
                                 delegateQueue: nil)
        
        let haapiClient = haapiTokenManager.createClient(urlSession: session)
        self.haapiClient = haapiClient

        guard let authorizationUrl = self.authorizationUrl else {
            handleError(HaapiControllerErrors.invalidUrl, withOnErrorCallback: onError)
            return
        }

        var request = URLRequest(url: authorizationUrl)
        request.httpMethod = "GET"
        
        haapiClient.performDataTask(for: request) { result in
            do {
                switch result {
                case .success(let responseAndData):
                    guard let httpResponse = responseAndData.response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                        throw HaapiControllerErrors.serverError(statusCode: (responseAndData.response as? HTTPURLResponse)?.statusCode ?? 0)
                    }
                    
                    guard let data = responseAndData.data else {
                        throw HaapiControllerErrors.noResponseData
                    }
                    
                    let representation = try Representation.fromJson(data)
                    if self.globalSettings.followRedirects,
                       let redirectionStep = RedirectionStep.fromRepresentation(representation) {
                        logger.debug("Following redirect")

                        //TODO: Reason about if onSuccess should be passed on
                        self.submitForm(
                            form: redirectionStep.redirectForm,
                            onError: onError,
                            willCommitState: willCommitState
                        )
                    } else {
                        self.commitState(HaapiState(representation: representation), willCommitState: willCommitState, clearFieldStateCaches: true)
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                self.handleError(error, withOnErrorCallback: onError)
            }
        }
    }
    
    override func reset() {
        logger.info("Resetting HAAPI flow")
        DispatchQueue.main.async {
            self.haapiClient = nil
            self.commitState(nil, clearFieldStateCaches: true)
        }
    }
    
    override func submitForm(
        form: FormModel,
        parameterOverrides: [String: String] = [:],
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        startTransition()
        
        do {
            let url = try getUrl(href: form.href)
            let formParameters = curateFormParameters(form: form, parameterOverrides: parameterOverrides)
            var request: URLRequest
            
            if form.method == "GET" {
                request = URLRequest(url: url.withQuery(parameters: formParameters))
            } else {
                request = URLRequest(url: url)
                request.httpBody = formParametersToBodyData(parameters: formParameters)
            }
            
            request.httpMethod = form.method
            
            logger.info("Submitting HAAPI Form; url=\(url.absoluteString), parameters=\(formParameters)")
            callHaapi(
                request: request,
                continueActions: form.continueActions,
                onError: onError,
                willCommitState: willCommitState
            )
        } catch {
            handleError(error, withOnErrorCallback: onError)
        }
    }

    override func followLink(
        link: Link,
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        startTransition()

        do {
            let url = try getUrl(href: link.href)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            logger.info("Getting HAAPI Link; url=\(url.absoluteString)")
            callHaapi(
                request: request,
                continueActions: [],
                onError: onError,
                willCommitState: willCommitState
            )
        } catch {
            handleError(error, withOnErrorCallback: onError)
        }
    }
    
    override func handleContinueActions(
        continueActions: [Action],
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        startTransition()
        
        do {
            if self.globalSettings.followRedirects,
               continueActions.count == 1,
               let action = continueActions.first,
               let redirectionStep = RedirectionStep.fromAction(action) {
                logger.debug("Following redirect")

                self.submitForm(
                    form: redirectionStep.redirectForm,
                    onError: onError,
                    willCommitState: willCommitState
                )
            } else {
                try commitContinueState(continueActions: continueActions, willCommitState: willCommitState)
            }
        } catch {
            handleError(error, withOnErrorCallback: onError)
        }
    }

    private func getUrl(href: String) throws -> URL {
        guard let baseUrl = URL(string: globalSettings.baseUrl),
              let url = URL(string: href, relativeTo: baseUrl) else {
            throw HaapiControllerErrors.illegalState(message: "Invalid URL: '\(href)' relative to '\(globalSettings.baseUrl)'")
        }

        return url
    }

    private func callHaapi(request: URLRequest, continueActions: [Action], onError: @escaping OnError, willCommitState: @escaping OnCommitState) {
        do {
            guard let haapiClient = self.haapiClient else {
                throw HaapiControllerErrors.illegalState(message: "No HAAPI Client")
            }

            let useDelayedDataTask = false
            performBlock({
                haapiClient.performDataTask(for: request) { result in
                    switch result {
                    case .success(let responseAndData):
                        self.onRequestSuccess(responseAndData: responseAndData, continueActions: continueActions, onError: onError, willCommitState: willCommitState)
                    case .failure(let error):
                        self.handleError(error, withOnErrorCallback: onError)
                    }
                }
            }, afterDelay: useDelayedDataTask ? 2 : 0)
        } catch {
            handleError(error, withOnErrorCallback: onError)
        }
    }

    private func onRequestSuccess(
        responseAndData: ResponseAndData,
        continueActions: [Action],
        onError: @escaping OnError,
        willCommitState: @escaping OnCommitState
    ) {
        do {
            guard let httpResponse = responseAndData.response as? HTTPURLResponse,
                httpResponse.statusCode < 500 else {
                throw HaapiControllerErrors.serverError(statusCode: (responseAndData.response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            guard let data = responseAndData.data else {
                throw HaapiControllerErrors.noResponseData
            }

            logger.debug("Representation received: \(String(data: data, encoding: .utf8) ?? "-")")

            let representation = try Representation.fromJson(data)

            if let problem = Problem.from(representation) {
                self.commitProblemState(
                    problem: problem,
                    representation: representation,
                    willCommitState: willCommitState
                )
            } else if case .continueSameStep = representation.type {
                try self.commitContinueState(
                    continueActions: continueActions,
                    willCommitState: willCommitState
                )
            } else if self.globalSettings.followRedirects,
                      let redirectionStep = RedirectionStep.fromRepresentation(representation) {
                logger.debug("Following redirect")

                self.submitForm(
                    form: redirectionStep.redirectForm,
                    onError: onError,
                    willCommitState: willCommitState
                )
            } else if self.globalSettings.followRedirects,
                      let pollingStep = PollingStep.from(representation),
                      case PollingStatus.done = pollingStep.status,
                      let doneForm = pollingStep.doneForm {
                logger.debug("Following polling done redirect")

                self.submitForm(
                    form: doneForm,
                    onError: onError,
                    willCommitState: willCommitState
                )
            } else if self.globalSettings.followRedirects,
                      let pollingStep = PollingStep.from(representation),
                      case PollingStatus.failed = pollingStep.status,
                      let failedForm = pollingStep.failedForm {
                logger.debug("Following polling failed redirect")

                self.submitForm(
                    form: failedForm,
                    onError: onError,
                    willCommitState: willCommitState
                )
            } else {
                self.commitState(
                    representation: representation,
                    willCommitState: willCommitState,
                    clearFieldStateCaches: true
                )
            }
        } catch {
            self.handleError(error, withOnErrorCallback: onError)
        }
    }
    
    func curateFormParameters(form: FormModel, parameterOverrides: [String: String]) -> [String: String] {
        var formParameters = [String: String]()
        
        for field in form.fields {
            let name = field.name
            
            if let value = parameterOverrides[name] {
                formParameters[name] = value
            } else if field.type == .checkbox {
                if let toggleFieldState = toggleFieldStates.first(where: { $0.fieldId == field.uuid}), toggleFieldState.boolValue {
                        formParameters[name] = field.value
                }
            } else if let textFieldState = textFieldTextStates.first(where: { $0.textFieldId == field.uuid }) {
                formParameters[name] = textFieldState.text
            } else if let value = field.value {
                formParameters[name] = value
            }
        }
        
        return formParameters
    }
    
    func formParametersToBodyData(parameters: [String: String]) -> Data? {
        guard !parameters.isEmpty else {
            return nil
        }
        
        var body = URLComponents()
        
        body.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        return body.query?.data(using: .utf8)
    }
}

class TrustAllCertsDelegate: NSObject, URLSessionDelegate {
    let logger = Logger()

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        logger.trace("Session Authentication challenge received")

        var credential: URLCredential?
        let serverTrust = challenge.protectionSpace.serverTrust
        if let serverTrust = serverTrust {
            logger.debug("Trusting certificate")
            credential = URLCredential(trust: serverTrust)
        }

        completionHandler(.useCredential, credential)
    }
}
