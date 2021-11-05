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
import HaapiModelsSDK
import os
import UIKit

protocol FlowViewModelSubmitable: AnyObject {
    func submitForm(form: FormActionModel,
                    parameterOverrides: [String: String],
                    completionHandler: @escaping () -> Void)
}

protocol TokenServices: AnyObject {
    func fetchAccessToken(code: String)
    func refreshAccessToken(refreshToken: String)
}

/**
 FlowViewModel is representing a ViewModel that is aware of all HaapiState from `HaapiController`. This class interacts directly with `HaapiController`
 and has available methods to do that.

 This class is mainly used with SwiftUI. `FlowViewModel.state` and `FlowViewModel.isProcessing` are **@Published** parameters.
 With these parameters, you can be notified when a state has changed or when an interaction has been triggered.

 For UI layer and cusomization, check the viewModels or the following parameters : `FlowViewModel.messages`,
 `FlowViewModel.links`,  `FlowViewModel.title` or `FlowViewModel.imageLogo`.
 */
// swiftlint:disable:next type_body_length
final class FlowViewModel: ObservableObject, FlowViewModelSubmitable, TokenServices {

    static let isProcessingNotification = NSNotification.Name("flowViewModel.isProcessing")
    static let problemRepresentationNotification = NSNotification.Name("flowViewModel.problemRepresentation")

    // MARK: @Published

    @Published var isProcessing = false {
        didSet {
            notificationCenter.post(name: Self.isProcessingNotification,
                                    object: isProcessing)
        }
    }

    @Published var haapiRepresentation: HaapiRepresentation?
    @Published var problemRepresentation: ProblemRepresentation? {
        didSet {
            notificationCenter.post(name: Self.problemRepresentationNotification,
                                    object: problemRepresentation)
        }
    }
    @Published var error: ErrorInfo?

    // MARK: Configurations
    private var haapiManager: HaapiManager?
    private var oauthTokenService: OAuthTokenService?
    private var profile: Profile?

    private let notificationCenter: NotificationCenter

    private var pollingStatus: PollingStatus?

    // MARK: Support UI

    var messageBundles: [MessageBundle] {
        return haapiRepresentation?.messages.map {
            MessageBundle(text: $0.text.value(), messageType: $0.messageType)
        } ?? []
    }

    private(set) var title: String = ""
    private(set) var imageLogo = "Logo"

    // MARK: - ViewModels

    /// A `SelectorViewModel`is generated from `[Action]`. This ViewModel is used by a `SelectorView`.
    private(set) var selectorViewModel: SelectorViewModel?
    /// A `[FormViewModel]`is generated from `[Action]`. This ViewModel is used by a `FormView`.
    private(set) var formViewModels = [FormViewModel]()
    /// A `PollingViewModel`is generated when HaapiState is `polling`. This ViewModel is used by a `PollingView`.
    private(set) var pollingViewModel: PollingViewModel?
    /// An `AuthorizedViewModel`is generated when HaapiState is `authorizationResponse`. This ViewModel is used by an `AuthorizedView`.
    private(set) var authorizedViewModel: AuthorizedViewModel?
    /// A `TokensViewModel`is generated when HaapiState is `accessToken`. This ViewModel is used by a `TokensView`.
    private(set) var tokensViewModel: TokensViewModel?

    // MARK: Init & Deinit

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Process HaapiResult

    private func processHaapiResult(_ haapiResult: HaapiResult) {
        DispatchQueue.main.async {
            self.isProcessing = false
        }
        
        switch haapiResult {
        case .representation(let representation):
            print(representation)
            processHaapiRepresentation(representation)
            DispatchQueue.main.async {
                self.haapiRepresentation = representation
            }
        case .operation(let operationStep):
            print(operationStep)
            processOperationStep(operationStep)
        case .problem(let problemRepresentation):
            print(problemRepresentation)
            processProblemRepresentation(problemRepresentation)
        case .error(let error):
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: "Unexpected error",
                                       reason: error.localizedDescription)
            }
        }
    }

    private func openExternalApp(externalURL: URL,
                                 succeedAction: FormAction?,
                                 failedAction: FormAction?)
    {
        DispatchQueue.main.async {
            UIApplication.shared.open(externalURL, options: [:]) { succeed in
                if succeed {
                    Logger.clientApp.debug("Did open external application")
                    if let succeedAction = succeedAction {
                        self.haapiManager?.applyFormAction(succeedAction,
                                                           infoMessage: nil,
                                                           completionHandler:
                        { haapiResult in
                            self.processHaapiResult(haapiResult)
                        })
                    }
                } else {
                    Logger.clientApp.debug("Cannot open external application")
                    if let failedAction = failedAction {
                        self.haapiManager?.applyFormAction(failedAction,
                                                           infoMessage: "Cannot open an external application",
                                                           completionHandler:
                        { haapiResult in
                            self.processHaapiResult(haapiResult)
                        })
                    }
                }
            }
        }
    }

    private var pendingOperationStep: OperationStep?
    private func processOperationStep(_ operationStep: OperationStep) {
        pendingOperationStep = operationStep
        switch operationStep {
        case let externalBrowserStep as ExternalBrowserOperationStep:
            guard let externalURL = externalBrowserStep.externalURL else {
                Logger.clientApp.debug("No external URL")
                return
            }
            openExternalApp(externalURL: externalURL,
                            succeedAction: externalBrowserStep.succeedOpeningOperationAction,
                            failedAction: externalBrowserStep.failedOpeninigOperationAction)
        case let bankIdStep as BankIdOperationStep:
            guard let bankIDURL = bankIdStep.externalURL else {
                Logger.clientApp.debug("No external URL")
                return
            }
            openExternalApp(externalURL: bankIDURL,
                            succeedAction: bankIdStep.succeedOpeningOperationAction,
                            failedAction: bankIdStep.failedOpeninigOperationAction)
        default:break
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func processHaapiRepresentation(_ representation: HaapiRepresentation) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil

        if !(representation is PollingStep) {
            pollingViewModel = nil
        }

        switch representation {
        case let selectorStep as AuthenticatorSelectorStep:
            title = selectorStep.title.value()
            let options = selectorStep.authenticators.map { authOption in
                SelectorViewModel.SelectorOption(imageName: authOption.imageName,
                                                 title: authOption.title.value(),
                                                 formActionModel: authOption.action.model)
            }
            selectorViewModel = SelectorViewModel(options: options,
                                                  submitter: self)
        case let redirectionStep as RedirectionStep:
            title = "Redirection"
            let fieldViewModels = redirectionStep.actionForm.model.fields.visibleFieldViewModel
            formViewModels.append(FormViewModel(formAction: redirectionStep.actionForm,
                                                title: nil,
                                                fieldViewModels: fieldViewModels,
                                                submitter: self))
        case is AuthenticationStep, is RegistrationStep:
            var shouldShowSectionTitle = false
            if representation.actions.count == 1 {
                if let actionTitle = representation.actions.first?.title?.value() {
                    title = actionTitle
                } else {
                    title = representation is AuthenticationStep ? "Authentication" : "Registration"
                }
            } else {
                shouldShowSectionTitle = true
                title = representation is AuthenticationStep ? "Authentication" : "Registration"
            }
            representation.actions.forEach { action in
                guard let formAction = action as? FormAction else { return }
                let fieldViewModels = formAction.model.fields.visibleFieldViewModel
                formViewModels.append(FormViewModel(formAction: formAction,
                                                    title: shouldShowSectionTitle ? formAction.title?.value() : nil,
                                                    fieldViewModels: fieldViewModels,
                                                    submitter: self))
            }
        case let oAuthStep as OAuthAuthorizationResponseStep:
            guard let code = oAuthStep.oauthAuthorizationResponseProperties.code else {
                fatalError("How to recover from it ?")
            }
            if profile?.followRedirects == true {
                fetchAccessToken(code: code)
            } else {
                title = "OAuth authorization completed"
                authorizedViewModel = AuthorizedViewModel(authorizationCode: code,
                                                          tokenServices: self)
            }
        case let pollingStep as PollingStep:
            if pollingStatus != pollingStep.pollingProperties.status {
                title = "Polling"
                pollingStatus = pollingStep.pollingProperties.status
                pollingViewModel = PollingViewModel(pollingStep: pollingStep,
                                                    submitter: self,
                                                    automaticPolling: profile?.automaticPolling == true)
            } else {
                // swiftlint:disable:next line_length
                Logger.controllerFlow.debug("Ignoring new polling step: \(pollingStep.pollingProperties.status.rawValue)")
            }
        default: break
        }
    }

    private func processProblemRepresentation(_ problem: ProblemRepresentation) {
        switch problem {
        case let authorizationProblem as AuthorizationProblem:
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: authorizationProblem.error,
                                       reason: authorizationProblem.errorDescription)
            }
        default:
            DispatchQueue.main.async {
                self.problemRepresentation = problem
            }
        }
    }

    // MARK: - Haapi Manager

    /**
     Starts the HaapiFlow according to the provided `Profile` and invokes the `completionHandler`.
     - Parameter profile: A `Profile` that contains the configurations for Haapi.
     - Parameter completionHandler: A closure that returns a `Boolean` indicating if the call was or not a success.
     */
    func start(_ profile: Profile,
               completionHandler: @escaping (Bool) -> Void)
    {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        guard let baseURL = URL(string: profile.baseURLString),
              let tokenEndpointURL = URL(string: profile.tokenEndpointURI),
              let authorizationEndpointURL = URL(string: profile.authorizationEndpointURI),
              let appRedirect = Bundle.main.haapiRedirectURI else
        {
            completionHandler(false)
            return
        }
        self.profile = profile
        let urlSession = URLSession(configuration: URLSessionConfiguration.haapiFlow,
                                    delegate: profile.isDefaultAuthChallengeEnabled ? nil : TrustAllCertsDelegate(),
                                    delegateQueue: nil)
        let haapiConfiguration = HaapiConfiguration(name: profile.name,
                                                    clientId: profile.clientId,
                                                    baseURL: baseURL,
                                                    tokenEndpointURL: tokenEndpointURL,
                                                    authorizationEndpointURL: authorizationEndpointURL,
                                                    appRedirectURIString: appRedirect,
                                                    isAutoRedirect: profile.followRedirects,
                                                    scopes: profile.selectedScopes ?? [],
                                                    urlSession: urlSession)

        haapiManager = HaapiManager(haapiConfiguration: haapiConfiguration)
        oauthTokenService = OAuthTokenService(haapiConfiguration: haapiConfiguration)

        haapiManager?.start{ haapiResult in
            self.processHaapiResult(haapiResult)
            switch haapiResult {
            case .error, .problem:
                completionHandler(false)
            default:
                completionHandler(true)
            }
        }
    }

    /**
     Submits a `FormModel`with a dictionary `parameterOverrides` and invokes the `completionHandler`.
     - Parameter form: A `FormModel`
     - Parameter parametersOverrides: A dictionary of String that will override any possible keys from `FormModel`.
     - Parameter completionHAndler: A closure of `HaapiCompletionHandler` that returns an optional `HaapiState`.
     */
    func submitForm(form: FormActionModel,
                    parameterOverrides: [String: String],
                    completionHandler: @escaping () -> Void)
    {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }

        haapiManager?.submitForm(form,
                                 parameters: parameterOverrides,
                                 completionHandler:
        { haapiResult in
            self.processHaapiResult(haapiResult)
            completionHandler()
        })
    }

    /**
     Follows a `Link` and invokes the `completionHandler`.
     - Parameter link: A `Link`
     - Parameter completionHandler: An optional closure of `HaapiCompletionHandler` that returns an optional `HappiState`
     */
    func followLink(link: Link) {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }

        haapiManager?.followLink(link,
                                 completionHandler:
        { haapiResult in
            self.processHaapiResult(haapiResult)
        })
    }

    // MARK: - HaapiManager client operations

    func canHandleURL(_ url: URL) -> Bool {
        guard let haapiManager = haapiManager else { return false }

        return haapiManager.canHandleURL(url)
    }

    func handleURL(_ url: URL) {
        guard let haapiManager = haapiManager,
              let extBrowserStep = pendingOperationStep as? ExternalBrowserOperationStep,
              let continueAction = extBrowserStep.continueAction
        else {
            fatalError("There is no haapiManager - The flow was not started or canHandleURL was not called")
        }
        do {
            let formattedParameters = try haapiManager.formattedParametersFromURL(url)
            submitForm(form: continueAction.model, parameterOverrides: formattedParameters, completionHandler: {})
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: Token service

    func fetchAccessToken(code: String) {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }

        oauthTokenService?.fetchAccessToken(with: code,
                                            completionHandler:
        { oAuthResponse in
            DispatchQueue.main.async {
                self.processOAuthResponse(oAuthResponse)
                self.isProcessing = false
            }
        })
    }

    func refreshAccessToken(refreshToken: String) {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }

        oauthTokenService?.refreshAccessToken(with: refreshToken,
                                              completionHandler:
        { oAuthResponse in
            DispatchQueue.main.async {
                self.processOAuthResponse(oAuthResponse)
                self.isProcessing = false
            }
        })
    }

    private func processOAuthResponse(_ oAuthResponse: OAuthResponse) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil

        print(oAuthResponse)
        switch oAuthResponse {
        case .token(let tokenResponse):
            title = "Success"
            tokensViewModel = TokensViewModel(tokenResponse, tokenServices: self)
        case .invalid(let invalidTokenResponse):
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: invalidTokenResponse.error,
                                       reason: invalidTokenResponse.errorDescription)
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: "Unexpected error",
                                       reason: error.localizedDescription)
            }
        }
    }

    // MARK: Reset

    /// Resets the HaapiFlow by clearing the internal state and notify the controller to reset itself.
    func reset() {
        resetState()
        haapiManager?.close()
        haapiManager = nil
    }

    /// Resets the internal state of FlowViewModel
    private func resetState() {
        isProcessing = false

        haapiRepresentation = nil
        error = nil

        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        tokensViewModel = nil
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

private let defaultImageName = "icon-user"
private extension AuthenticatorSelectorStep.AuthenticatorOption {

    var imageName: String {
        guard let type = type else { return defaultImageName }

        var result = "icon-\(type)"
        if UIImage(named: result) == nil {
            result = defaultImageName
        }
        return result
    }
}

private extension Array where Element == FormField {
    var visibleFormField: [FormField] {
        return filter { $0.type != .hidden }
    }

    var visibleFieldViewModel: [FieldViewModel] {
        return visibleFormField.map {
            if let formFieldCheckbox = $0 as? FormFieldCheckbox{
                return CheckboxViewModel(checkboxField: formFieldCheckbox)
            } else if let formFieldSelect = $0 as? FormFieldSelect {
                return OptionsViewModel(selectField: formFieldSelect)
            } else {
                return FieldViewModel(field: $0)
            }
        }
    }
}
