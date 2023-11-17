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
import IdsvrHaapiSdk
import os
import UIKit

protocol FlowViewModelSubmitable: AnyObject {
    func submitForm(form: FormActionModel,
                    parameterOverrides: [String: Any],
                    completionHandler: @escaping () -> Void)
}

protocol TokenServices: AnyObject {
    func fetchAccessToken(code: String)
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
final class FlowViewModel: NSObject, ObservableObject, FlowViewModelSubmitable, TokenServices {
    
    static let isProcessingNotification = NSNotification.Name("flowViewModel.isProcessing")
    static let problemRepresentationNotification = NSNotification.Name("flowViewModel.problemRepresentation")
    
    // MARK: @Published
    
    @Published var isProcessing = false {
        didSet {
            notificationCenter.post(name: Self.isProcessingNotification,
                                    object: isProcessing)
        }
    }
    
    @Published private(set) var haapiRepresentation: HaapiRepresentation?
    @Published private(set) var problemRepresentation: ProblemRepresentation? {
        didSet {
            notificationCenter.post(name: Self.problemRepresentationNotification,
                                    object: problemRepresentation)
        }
    }
    @Published private(set) var error: ErrorInfo?
    @Published private(set) var tokenResponse: SuccessfulTokenResponse?
    
    // MARK: Configurations
    private var haapiManager: HaapiManager?
    private var oauthTokenManager: OAuthTokenManager?
    private var profile: Profile?
    
    private let notificationCenter: NotificationCenter
    
    private var pollingStatus: PollingStatus?
    private var storedPollingStep: PollingStep?
    
    // MARK: Support UI
    
    var messageBundles: [MessageBundle] {
        return haapiRepresentation?.messages.map {
            MessageBundle(text: $0.text.literal, messageType: $0.messageType)
        } ?? []
    }
    
    private(set) var title: String = ""
    private(set) var imageLogo = "Logo"
    
    internal var selectedWebauthnAuthenticator: WebauthnAttachmentType?
    
    // MARK: - ViewModels
    
    /// A `SelectorViewModel`is generated from `[Action]`. This ViewModel is used by a `SelectorView`.
    private(set) var selectorViewModel: SelectorViewModel?
    /// A `[FormViewModel]`is generated from `[Action]`. This ViewModel is used by a `FormView`.
    private(set) var formViewModels = [FormViewModel]()
    /// A `PollingViewModel`is generated when HaapiState is `polling`. This ViewModel is used by a `PollingView`.
    private(set) var pollingViewModel: PollingViewModel?
    /// An `AuthorizedViewModel`is generated when HaapiState is `authorizationResponse`. This ViewModel is used by an `AuthorizedView`.
    private(set) var authorizedViewModel: AuthorizedViewModel?
    /// A `GenericHaapiViewModel` for a GenericRepresentationStep
    private(set) var genericHaapiViewModel: GenericHaapiViewModel?
    /// A `WebauthnAuthenticatorsViewModel` for a WebauthnClientOperation
    private(set) var webauthnViewModel: WebauthnAuthenticatorsViewModel?
    
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
            if let clientOperationStep = representation as? ClientOperationStep {
                Logger.controllerFlow.debug("Received an operation: \(String(describing: clientOperationStep))")
                processOperationStep(clientOperationStep, updateState: {
                    DispatchQueue.main.async {
                        self.haapiRepresentation = clientOperationStep
                    }
                })
            } else {
                Logger.controllerFlow.debug("Received a representation: \(String(describing: representation))")
                processHaapiRepresentation(representation)
                DispatchQueue.main.async {
                    self.haapiRepresentation = representation
                }
            }
        case .problem(let problemRepresentation):
            Logger.controllerFlow.debug("Received a problem: \(String(describing: problemRepresentation))")
            processProblemRepresentation(problemRepresentation)
        case .error(let error):
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: "Unexpected error",
                                       reason: error.localizedDescription)
            }
        }
    }
    
    private func prepareFormViewModelsForActions(_ actions: [Action],
                                                 defaultTitle: String)
    {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
        
        var shouldShowSectionTitle = false
        if actions.count == 1 {
            if let actionTitle = actions.first?.title?.literal {
                title = actionTitle
            } else {
                title = defaultTitle
            }
        } else {
            shouldShowSectionTitle = true
            title = defaultTitle
        }
        actions.forEach { action in
            guard let formAction = action as? FormAction else { return }
            let fieldViewModels = formAction.model.fields.visibleFieldViewModel
            formViewModels.append(FormViewModel(formAction: formAction,
                                                title: shouldShowSectionTitle ? formAction.title?.literal : nil,
                                                fieldViewModels: fieldViewModels,
                                                submitter: self))
        }
    }
    
    internal var pendingOperationStep: ClientOperationStep?
    
    private func processOperationStep(_ operationStep: ClientOperationStep, updateState: @escaping (() -> Void)) {
        pendingOperationStep = operationStep
        switch operationStep {
        case let externalBrowserStep as ExternalBrowserClientOperationStep:
            guard let redirect = Bundle.main.haapiRedirectURI,
                  let externalURL = externalBrowserStep.urlToLaunch(redirectTo: redirect)
            else {
                Logger.clientApp.debug("No external URL")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.open(externalURL, options: [:]) { succeed in
                    if succeed {
                        self.prepareFormViewModelsForActions(externalBrowserStep.actionsToPresent,
                                                             defaultTitle: "External browser operation")
                        updateState()
                    } else {
                        self.error = ErrorInfo(title: "No available web browser",
                                               reason: "A web browser is required")
                    }
                }
            }
        case let bankIdStep as BankIdClientOperationStep:
            
            // BankID logic in versions of the Curity Identity Server older than 8.0
            guard let redirect = Bundle.main.haapiRedirectURI,
                  let bankIDURL = bankIdStep.urlToLaunch(redirectTo: redirect) else {
                Logger.clientApp.debug("No external URL")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.open(bankIDURL, options: [:]) { succeed in
                    if succeed {
                        self.prepareFormViewModelsForActions(bankIdStep.continueActions,
                                                             defaultTitle: "Bank ID operation")
                    } else {
                        self.prepareFormViewModelsForActions(bankIdStep.errorActions,
                                                             defaultTitle: "Bank ID operation error")
                    }
                    updateState()
                }
            }
        case let webauthnRegistrationOperationStep as WebAuthnRegistrationClientOperationStep:
            Logger.clientApp.debug("A webauthnOperationStep: \(webauthnRegistrationOperationStep.type.rawValue)")
            prepareWebAuthnRegistration(webauthnRegistrationOperationStep, updateState: updateState)
        case let webauthnAssertionOperationStep as WebAuthnAuthenticationClientOperationStep:
            Logger.clientApp.debug("A webauthnOperationStep: \(webauthnAssertionOperationStep.type.rawValue)")
            prepareWebAuthnAssertion(webauthnAssertionOperationStep, updateState: updateState)
        default:
            Logger.clientApp.debug("No behaviour defined for: \(String(describing: operationStep))")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func processHaapiRepresentation(_ representation: HaapiRepresentation) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
        
        if !(representation is PollingStep) {
            pollingViewModel = nil
        }
        
        switch representation {
        case let selectorStep as AuthenticatorSelectorStep:
            title = selectorStep.title.literal
            let options = selectorStep.authenticators.map { authOption in
                SelectorViewModel.SelectorOption(imageName: authOption.imageName,
                                                 title: authOption.title.literal,
                                                 formActionModel: authOption.action.model)
            }
            selectorViewModel = SelectorViewModel(options: options,
                                                  submitter: self)
        case let redirectionStep as RedirectionStep:
            title = "Redirection"
            let fieldViewModels = redirectionStep.redirectAction.model.fields.visibleFieldViewModel
            formViewModels.append(FormViewModel(formAction: redirectionStep.redirectAction,
                                                title: nil,
                                                fieldViewModels: fieldViewModels,
                                                submitter: self))
        case let interactiveFormStep as InteractiveFormStep:
            var shouldShowSectionTitle = false
            if interactiveFormStep.actions.count == 1 {
                if let actionTitle = interactiveFormStep.actions.first?.title?.literal {
                    title = actionTitle
                } else {
                    title = interactiveFormStep.type == .authenticationStep
                    ? "Authentication" : interactiveFormStep.type == .registrationStep
                    ? "Registration" : "User consent"
                }
            } else {
                shouldShowSectionTitle = true
                title = representation.type == .authenticationStep
                ? "Authentication" : representation.type == .registrationStep
                ? "Registration" : "User consent"
            }
            
            interactiveFormStep.actions.forEach { formAction in
                let fieldViewModels = formAction.model.fields.visibleFieldViewModel
                formViewModels.append(FormViewModel(formAction: formAction,
                                                    title: shouldShowSectionTitle ? formAction.title?.literal : nil,
                                                    fieldViewModels: fieldViewModels,
                                                    submitter: self))
            }
        case let userConsentStep as UserConsentStep:
            var shouldShowSectionTitle = false
            if userConsentStep.actions.count == 1 {
                if let actionTitle = userConsentStep.actions.first?.title?.literal {
                    title = actionTitle
                } else {
                    title = "User consent"
                }
            } else {
                shouldShowSectionTitle = true
                title = "User consent"
            }
            userConsentStep.actions.forEach { action in
                guard let formAction = action as? FormAction else { return }
                let fieldViewModels = formAction.model.fields.visibleFieldViewModel
                formViewModels.append(FormViewModel(formAction: formAction,
                                                    title: shouldShowSectionTitle ? formAction.title?.literal : nil,
                                                    fieldViewModels: fieldViewModels,
                                                    submitter: self))
            }
        case let oAuthStep as OAuthAuthorizationResponseStep:
            guard let code = oAuthStep.oauthAuthorizationResponseProperties.code else {
                fatalError("How to recover from it ?")
            }
            if profile?.followRedirects == true {
                DispatchQueue.main.async {
                    self.fetchAccessToken(code: code)
                }
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
                if pollingStatus == .done,
                   profile?.followRedirects == true
                {
                    submitForm(form: pollingStep.mainAction.model,
                               parameterOverrides: [:],
                               completionHandler: {})
                }
            
                startBankIdIfRequired(pollingStep: pollingStep)

            } else {

                // swiftlint:disable:next line_length
                Logger.controllerFlow.debug("Ignoring new polling step: \(pollingStep.pollingProperties.status.rawValue)")
            }
            
            endBankIdIfRequired(pollingStep: pollingStep)
            
        case let genericRepresentationStep as GenericRepresentationStep:
            if genericRepresentationStep.actions.count == 1 {
                title = genericRepresentationStep.actions.first?.title?.literal ?? "Generic step"
            } else {
                title = "Generic step"
            }
            genericHaapiViewModel = GenericHaapiViewModel(genericRepresentationStep: genericRepresentationStep,
                                                          submitter: self)
        default: break
        }
    }
    
    // Logic to start interaction with BankID in version 8.0 or later of the Curity Identity Server
    private func startBankIdIfRequired(pollingStep: PollingStep) {
        
        if storedPollingStep != nil {
            return
        }

        if let clientOperation = pollingStep.actions.first(
            where: { $0 is ClientOperationAction }) as? ClientOperationAction {
            if let bankIdActionModel = clientOperation.model as? BankIdClientOperationActionModel {
                
                guard let redirect = Bundle.main.haapiRedirectURI,
                      let bankIDURL = bankIdActionModel.urlToLaunch(redirectTo: redirect) else {
                        Logger.clientApp.debug("No external URL")
                        return
                }
                
                storedPollingStep = pollingStep
                DispatchQueue.main.async {
                    UIApplication.shared.open(bankIDURL, options: [:]) { succeed in
                        if succeed {
                            self.prepareFormViewModelsForActions(bankIdActionModel.continueActions,
                                                                 defaultTitle: "Bank ID operation")
                        } else {
                            self.prepareFormViewModelsForActions(bankIdActionModel.errorActions,
                                                                 defaultTitle: "Bank ID operation error")
                        }
                    }
                }
            }
        }
    }
    
    // Logic to end interaction with BankID in version 8.0 or later of the Curity Identity Server
    private func endBankIdIfRequired(pollingStep: PollingStep) {
        
        if storedPollingStep != nil {
            if pollingStep.pollingProperties.status == PollingStatus.done || pollingStep.pollingProperties.status == PollingStatus.failed {
                storedPollingStep = nil
            }
        }
    }
    
    private func processProblemRepresentation(_ problem: ProblemRepresentation) {
        switch problem {
        case let authorizationProblem as AuthorizationProblem:
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: authorizationProblem.error,
                                       reason: authorizationProblem.errorDescription ?? authorizationProblem.error)
            }
        default:
            DispatchQueue.main.async {
                self.problemRepresentation = problem
            }
        }
    }
    
    // MARK: - WebAuthn
    // swiftlint:disable:next line_length
    private func prepareWebAuthnRegistration(_ webauthnRegistrationOperationStep: WebAuthnRegistrationClientOperationStep,
                                             updateState: @escaping (() -> Void)) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
        
        let shouldShowSelection = webauthnRegistrationOperationStep.actionModel.platformOptions != nil &&
        webauthnRegistrationOperationStep.actionModel.crossPlatformOptions != nil
        
        if #available(iOS 15.0, *) {
            if shouldShowSelection {
                title = webauthnRegistrationOperationStep.actionModel.continueActions.first?.title?.literal ?? ""
                
                self.webauthnViewModel = WebauthnAuthenticatorsViewModel(platformAction: {
                    self.doWebauthnRegistration(registrationModel: webauthnRegistrationOperationStep.actionModel,
                                                attachment: WebauthnAttachmentType.platformAttachment)
                },
                                                                         crossPlatformAction: {
                    self.doWebauthnRegistration(registrationModel: webauthnRegistrationOperationStep.actionModel,
                                                attachment: WebauthnAttachmentType.crossPlatformAttachment)
                })
                updateState()
            } else {
                if webauthnRegistrationOperationStep.actionModel.platformOptions != nil {
                    self.doWebauthnRegistration(registrationModel: webauthnRegistrationOperationStep.actionModel,
                                                attachment: WebauthnAttachmentType.platformAttachment)
                } else if webauthnRegistrationOperationStep.actionModel.crossPlatformOptions != nil {
                    self.doWebauthnRegistration(registrationModel: webauthnRegistrationOperationStep.actionModel,
                                                attachment: WebauthnAttachmentType.crossPlatformAttachment)
                }
            }
        } else {
            // show Fallback view interaction for earlier versions ex: using device with iOS14
            prepareWebAuthnError(canRetry: false, updateState: updateState)
        }
    }
    
    private func prepareWebAuthnAssertion(_ webauthnAssertionOperationStep: WebAuthnAuthenticationClientOperationStep,
                                          updateState: @escaping (() -> Void)) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
        
        // swiftlint:disable:next line_length
        let shouldShowSelection = webauthnAssertionOperationStep.actionModel.credentialOptions.platformAllowCredentials != nil &&
        webauthnAssertionOperationStep.actionModel.credentialOptions.crossPlatformAllowCredentials != nil
        
        if #available(iOS 15.0, *) {
            if shouldShowSelection {
                title = webauthnAssertionOperationStep.actionModel.continueActions.first?.title?.literal ?? ""
                
                self.webauthnViewModel = WebauthnAuthenticatorsViewModel(platformAction: {
                    self.doWebauthnAssertion(assertionModel: webauthnAssertionOperationStep.actionModel,
                                             attachment: WebauthnAttachmentType.platformAttachment)
                },
                                                                         crossPlatformAction: {
                    self.doWebauthnAssertion(assertionModel: webauthnAssertionOperationStep.actionModel,
                                             attachment: WebauthnAttachmentType.crossPlatformAttachment)
                })
                updateState()
            } else {
                if webauthnAssertionOperationStep.actionModel.credentialOptions.platformAllowCredentials != nil {
                    self.doWebauthnAssertion(assertionModel: webauthnAssertionOperationStep.actionModel,
                                             attachment: WebauthnAttachmentType.platformAttachment)
                } else if webauthnAssertionOperationStep.actionModel.credentialOptions.crossPlatformAllowCredentials != nil { // swiftlint:disable:this line_length
                    self.doWebauthnAssertion(assertionModel: webauthnAssertionOperationStep.actionModel,
                                             attachment: WebauthnAttachmentType.crossPlatformAttachment)
                }
            }
        } else {
            // show Fallback view interaction for earlier versions ex: using device with iOS14
            prepareWebAuthnError(updateState: updateState)
        }
    }
    
    func prepareWebAuthnError(canRetry: Bool = false, updateState: (() -> Void)? = nil){
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
        
        let modelErrorAction: Action? = getWebAuthnErrorAction()
        let retry: (() -> Void)? = buildWebAuthnErrorRetry(canRetry: canRetry)
        var isShowingSelection = false
        let platformAction: (() -> Void)? = buildWebAuthnErrorPlatformAction()
        let crossPlatformAction: (() -> Void)? = buildWebauthnErrorCrossPlatformAction()
        var retryActionType: String = ""
        if let registrationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            title = registrationStep.actionModel.continueActions.first?.title?.literal ?? ""
            isShowingSelection = registrationStep.actionModel.platformOptions != nil &&
            registrationStep.actionModel.crossPlatformOptions != nil
            retryActionType = "Registration"
        } else if let assertionStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep {
            title = assertionStep.actionModel.continueActions.first?.title?.literal ?? ""
            isShowingSelection = assertionStep.actionModel.credentialOptions.platformAllowCredentials != nil &&
            assertionStep.actionModel.credentialOptions.crossPlatformAllowCredentials != nil
            retryActionType = "Authentication"
        }
        
        var errorText = "An error has ocurred or WebAuthn is not supported by this device. Please open the browser"
        + " instead to complete the flow."
        var errorType = MessageType.error
        if canRetry {
            errorType = .info
            errorText = retryActionType + " of device was cancelled or timed out."
        }
        
        let problem = ProblemViewModel(title: "",
                                       messages: [ProblemMessageBundle(text: errorText, messageType: errorType)])
        
        let errorAction = {
            if modelErrorAction?.kind == ActionKind.redirect, let formAction = modelErrorAction as? FormAction {
                self.submitForm(form: formAction.model, parameterOverrides: [:]) {
                    self.selectedWebauthnAuthenticator = nil
                }
            }
        }
        
        if canRetry {
            if isShowingSelection {
                webauthnViewModel = WebauthnAuthenticatorsViewModel(problem: problem,
                                                                    platformAction: platformAction,
                                                                    crossPlatformAction: crossPlatformAction)
            } else {
                if let retryAction = retry {
                    webauthnViewModel = WebauthnAuthenticatorsViewModel(problem: problem,
                                                                        retryAction: retryAction,
                                                                        errorAction: errorAction)
                } else {
                    // should not get here, but handling just in case
                    webauthnViewModel = WebauthnAuthenticatorsViewModel(problem: problem,
                                                                        errorAction: errorAction)
                }
            }
        } else {
            // critical error - show only fallback
            webauthnViewModel = WebauthnAuthenticatorsViewModel(problem: problem,
                                                                errorAction: errorAction)
        }
        
        if let triggerUpdate = updateState {
            triggerUpdate()
        } else {
            // hack to force reload of StateView because the methods is being called in a place where there isn't a new
            // representation to present but we need UI update, ex: error thrown on authenticator API
            DispatchQueue.main.async {
                self.haapiRepresentation = self.pendingOperationStep
            }
        }
    }
    
    private func getWebAuthnErrorAction() -> Action? {
        var errorAction: Action?
        
        if let registrationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            errorAction = registrationStep.fallbackActions.first
        } else if let assertionStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep {
            errorAction = assertionStep.fallbackActions.first
        }
        
        return errorAction
    }
    
    private func buildWebAuthnErrorRetry(canRetry: Bool) -> (() -> Void)? {
        var retry: (() -> Void)?
        if let registrationStep = self.pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            title = registrationStep.actionModel.continueActions.first?.title?.literal ?? ""
            
            if canRetry, #available(iOS 15.0, *), let attachment = self.selectedWebauthnAuthenticator {
                retry = {
                    self.doWebauthnRegistration(registrationModel: registrationStep.actionModel,
                                                attachment: attachment)
                }
            }
        } else if let assertionStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep {
            if canRetry, #available(iOS 15.0, *), let attachment = self.selectedWebauthnAuthenticator {
                retry = {
                    self.doWebauthnAssertion(assertionModel: assertionStep.actionModel,
                                             attachment: attachment)
                }
            }
        }
        return retry
    }
    
    private func buildWebAuthnErrorPlatformAction() -> (() -> Void)? {
        var platformAction: (() -> Void)?
        if let registrationStep = self.pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            if registrationStep.actionModel.platformOptions != nil, #available(iOS 15.0, *) {
                platformAction = {
                    self.doWebauthnRegistration(registrationModel: registrationStep.actionModel,
                                                attachment: WebauthnAttachmentType.platformAttachment)
                }
            }
        } else if let assertionStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep {
            if assertionStep.actionModel.credentialOptions.platformAllowCredentials != nil, #available(iOS 15.0, *) {
                platformAction = {
                    self.doWebauthnAssertion(assertionModel: assertionStep.actionModel,
                                             attachment: WebauthnAttachmentType.platformAttachment)
                }
            }
        }
        return platformAction
    }
    
    private func buildWebauthnErrorCrossPlatformAction() -> (() -> Void)? {
        var crossPlatformAction: (() -> Void)?
        if let registrationStep = self.pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            if registrationStep.actionModel.platformOptions != nil, #available(iOS 15.0, *) {
                crossPlatformAction = {
                    self.doWebauthnRegistration(registrationModel: registrationStep.actionModel,
                                                attachment: WebauthnAttachmentType.crossPlatformAttachment)
                }
            }
        } else if let assertionStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep {
            if assertionStep.actionModel.credentialOptions.platformAllowCredentials != nil, #available(iOS 15.0, *) {
                crossPlatformAction = {
                    self.doWebauthnAssertion(assertionModel: assertionStep.actionModel,
                                             attachment: WebauthnAttachmentType.crossPlatformAttachment)
                }
            }
        }
        return crossPlatformAction
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
        guard let haapiConfiguration = profile.haapiConfiguration else {
            completionHandler(false)
            return
        }
        self.profile = profile
        
        // swiftlint:disable force_try
        haapiManager = try! HaapiManager(haapiConfiguration: haapiConfiguration)
        // swiftlint:enable force_try
        
        oauthTokenManager = OAuthTokenManager(oauthTokenConfiguration: haapiConfiguration)
        haapiManager?.start(completionHandler:
                                { haapiResult in
            self.processHaapiResult(haapiResult)
            switch haapiResult {
            case .error, .problem:
                completionHandler(false)
            default:
                completionHandler(true)
            }
        })
    }
    
    /**
     Submits a `FormModel`with a dictionary `parameterOverrides` and invokes the `completionHandler`.
     - Parameter form: A `FormModel`
     - Parameter parametersOverrides: A dictionary of String that will override any possible keys from `FormModel`.
     - Parameter completionHAndler: A closure of `HaapiCompletionHandler` that returns an optional `HaapiState`.
     */
    func submitForm(form: FormActionModel,
                    parameterOverrides: [String: Any],
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
        if let externalBrowser = pendingOperationStep as? ExternalBrowserClientOperationStep {
            return (try? externalBrowser.formattedParametersFromURL(url)) != nil
        } else {
            return false
        }
    }
    
    func handleURL(_ url: URL) {
        guard haapiManager != nil,
              let externalBrowserStep = pendingOperationStep as? ExternalBrowserClientOperationStep,
              let formattedParameters = try? externalBrowserStep.formattedParametersFromURL(url)
        else {
            fatalError("There is no haapiManager - The flow was not started or canHandleURL was not called")
        }
        
        submitForm(form: externalBrowserStep.continueFormActionModel,
                   parameterOverrides: formattedParameters,
                   completionHandler: {})
    }
    
    // MARK: Token service
    
    func fetchAccessToken(code: String) {
        guard !isProcessing else { return }
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        oauthTokenManager?.fetchAccessToken(with: code,
                                            completionHandler:
                                                { oAuthResponse in
            DispatchQueue.main.async {
                self.processOAuthResponse(oAuthResponse)
                self.isProcessing = false
            }
        })
    }
    
    private func processOAuthResponse(_ oAuthResponse: TokenResponse) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        
        Logger.controllerFlow.debug("Received an OAuthResponse: \(String(describing: oAuthResponse))")
        switch oAuthResponse {
        case .successfulToken(let successfulTokenResponse):
            title = "Success"
            self.tokenResponse = successfulTokenResponse
        case .errorToken(let errorTokenResponse):
            DispatchQueue.main.async {
                self.error = ErrorInfo(title: errorTokenResponse.error,
                                       reason: errorTokenResponse.errorDescription)
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
        oauthTokenManager = nil
    }
    
    /// Resets the internal state of FlowViewModel
    private func resetState() {
        isProcessing = false
        
        haapiRepresentation = nil
        error = nil
        
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil
        webauthnViewModel = nil
    }
    
    func clearTokenResponse() {
        tokenResponse = nil
    }
}

// MARK: - Private helpers

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

extension Array where Element == FormField {
    var visibleFormField: [FormField] {
        return filter { !($0 is HiddenFormField) }
    }
    
    var visibleFieldViewModel: [FieldViewModel] {
        return visibleFormField.map {
            if let formFieldCheckbox = $0 as? CheckboxFormField{
                return CheckboxViewModel(checkboxField: formFieldCheckbox)
            } else if let formFieldSelect = $0 as? SelectFormField {
                return OptionsViewModel(selectField: formFieldSelect)
            } else {
                return FieldViewModel(field: $0)
            }
        }
    }
}

extension Data {
    func toBase64Url() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}  // swiftlint:disable:this file_length
