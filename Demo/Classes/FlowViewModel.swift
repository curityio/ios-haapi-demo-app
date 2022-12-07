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
import AuthenticationServices

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
final class FlowViewModel: NSObject, ObservableObject, FlowViewModelSubmitable, TokenServices, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

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

    // MARK: Support UI

    var messageBundles: [MessageBundle] {
        return haapiRepresentation?.messages.map {
            MessageBundle(text: $0.text.literal, messageType: $0.messageType)
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
    /// A `GenericHaapiViewModel` for a GenericRepresentationStep
    private(set) var genericHaapiViewModel: GenericHaapiViewModel?

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
                processOperationStep(clientOperationStep)
                DispatchQueue.main.async {
                    self.haapiRepresentation = clientOperationStep
                }
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

    private var pendingOperationStep: ClientOperationStep?
    private func processOperationStep(_ operationStep: ClientOperationStep) {
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
                    } else {
                        self.error = ErrorInfo(title: "No available web browser",
                                               reason: "A web browser is required")
                    }
                }
            }
        case let bankIdStep as BankIdClientOperationStep:
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
                }
            }
        case let webauthnRegistrationOperationStep as WebAuthnRegistrationClientOperationStep:
            Logger.clientApp.debug("A webauthnOperationStep: \(webauthnRegistrationOperationStep.type.rawValue)")
            
            if let model = webauthnRegistrationOperationStep.actionModel.registration
            {
                if #available(iOS 15.0, *) {
                    doRegistrationCreation(registrationModel: model)
                } else {
                    // Fallback on earlier versions ex: using device with iOS14
                    if let registrationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
                        if let errorAction = registrationStep.actionModel.errorActions.first,
                            errorAction.kind == ActionKind.redirect,
                        let formAction = errorAction as? FormAction {
                            submitForm(form: formAction.model, parameterOverrides: [:]) {
                                
                            }
                        }
                    }
                }
            }
        case let webauthnAssertionOperationStep as WebAuthnAssertionClientOperationStep:
            Logger.clientApp.debug("A webauthnOperationStep: \(webauthnAssertionOperationStep.type.rawValue)")
            
            if let assertionRequest =  webauthnAssertionOperationStep.actionModel.assertion
            {
                if #available(iOS 15.0, *) {
                    doAssertionRequest(data: assertionRequest)
                } else {
                    // Fallback on earlier versions
                }
            }
        default:
            Logger.clientApp.debug("No behaviour defined for: \(String(describing: operationStep))")
            break
        }
    }

    @available(iOS 15.0, *)
    private func doRegistrationCreation(registrationModel: WebAuthnRegistrationClientOperationActionModel.PublicKey) {
        guard let authenticatorAttachment = registrationModel.authenticatorSelection?.authenticatorAttachment,
            let challengeData = registrationModel.challengeData,
              let userIdData = registrationModel.userIdData,
              let rpId = registrationModel.relyingPartyId,
              let userName = registrationModel.userName,
              let userPreference = registrationModel.authenticatorSelection?.userVerification else {
            fatalError("Invalid model registration")
        }

        var registrationRequest: ASAuthorizationRequest!
        
        switch authenticatorAttachment {
        case "platform":
            let credProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
            let registration = credProvider.createCredentialRegistrationRequest(challenge: challengeData,
                                                                                       name: userName,
                                                                                       userID: userIdData)
            if let displayName = registrationModel.displayName {
                registration.displayName = displayName
            }
            
            registration.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userPreference)
            
            if let attestationPref = registrationModel.attestation {
                registration.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(rawValue: attestationPref)
            }
            
            registrationRequest = registration
        default:
            let credProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
            let registration = credProvider.createCredentialRegistrationRequest(challenge: challengeData, displayName: userName, name: userName, userID: userIdData)
            
            if let displayName = registrationModel.displayName {
                registration.displayName = displayName
            }
            
            if let residentKeyPref = registrationModel.authenticatorSelection?.residentKey {
                registration.residentKeyPreference = ASAuthorizationPublicKeyCredentialResidentKeyPreference(rawValue: residentKeyPref)
            }
    
            registration.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userPreference)
            
            registration.excludedCredentials = registrationModel.excludedCredentials?.map { credential in
                let credTransports = credential.transports.map { transport in
                    return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport(rawValue: transport)
                }
                
                return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: credential.id, transports: credTransports)
            } ?? []
            
            if let attestationPref = registrationModel.attestation {
                registration.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(rawValue: attestationPref)
            }
    
            // add public key algorithms
            var algorithmParams = [ASAuthorizationPublicKeyCredentialParameters]()
            registrationModel.publicKeyCredParams?.forEach({ dictionary in
                algorithmParams.append(ASAuthorizationPublicKeyCredentialParameters(algorithm: ASCOSEAlgorithmIdentifier(rawValue:dictionary.algorithmId)))
            })
            registration.credentialParameters = algorithmParams
            
            registrationRequest = registration
        }
        
        let controller = ASAuthorizationController(authorizationRequests: [registrationRequest])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    @available(iOS 15.0, *)
    private func doAssertionRequest(data: WebAuthnAssertionClientOperationActionModel.PublicKey) {
        guard let challengeData = data.challengeData,
              let rpId = data.relyingPartyId,
              let userVerification = data.userVerificationPreference,
              let allowCredentials = data.allowCredentials
        else {
            fatalError("Invalid model for assertionModel")
        }
        
        // TODO: authenticator selection is not present in assertion request... necessary if supporting multiple authenticator providers
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)

        assertionRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerification)

        let allowedCredentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] = allowCredentials.map { cred in
            return ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: cred.idData)
        }

        assertionRequest.allowedCredentials = allowedCredentials

        let controller = ASAuthorizationController(authorizationRequests: [assertionRequest])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error)
    {
        Logger.clientApp.debug("Error for authorizationController: \(error.localizedDescription)")

        if let registrationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            if let errorAction = registrationStep.actionModel.errorActions.first,
                errorAction.kind == ActionKind.redirect,
            let formAction = errorAction as? FormAction {
                submitForm(form: formAction.model, parameterOverrides: [:]) {
                    
                }
            }
        }
        
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization)
    {
        if #available(iOS 15.0, *) {
            switch authorization.credential {
            case let credentialReg as ASAuthorizationPlatformPublicKeyCredentialRegistration:
                Logger.clientApp.debug("Authorization completed for registration")
                sendRegistration(credentialReg: credentialReg)
            case let assertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                Logger.clientApp.debug("Authorization completed for assertion")
                sendAssertion(credentialAssertion: assertion)
            default:
                fatalError("Not handled")
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let appWindow = UIApplication.shared.delegate?.window,
              let window = appWindow
        else {
            fatalError("There is no window")
        }
        return window
    }

    @available(iOS 15.0, *)
    private func sendRegistration(credentialReg: ASAuthorizationPlatformPublicKeyCredentialRegistration) {
        guard let operationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep else {
            fatalError("Expecting a GenericClientOperationStep")
        }

        guard let formAction = operationStep.continueAction,
              let attestationObject = credentialReg.rawAttestationObject else {
            fatalError("Developer mistake")
        }

        let webauthnParameters = operationStep.formattedParametersForRegistration(
          attestationObject: attestationObject,
          clientData: credentialReg.rawClientDataJSON,
          credentialID: credentialReg.credentialID)
        
        Logger.clientApp.debug("Raw client data JSON \(credentialReg.rawClientDataJSON.toBase64Url())")
        
        submitForm(form: formAction.model, parameterOverrides: webauthnParameters) {
            
        }
    }

    @available(iOS 15.0, *)
    private func sendAssertion(credentialAssertion: ASAuthorizationPlatformPublicKeyCredentialAssertion) {
        guard let operationStep = pendingOperationStep as? WebAuthnAssertionClientOperationStep else {
            fatalError("Expecting a GenericClientOperationStep")
        }

        guard let formAction = operationStep.continueAction else {
            fatalError("Developer mistake")
        }

        let assertionParams = operationStep.formattedParametersForAssertion(
          attestationObject: credentialAssertion.rawAuthenticatorData,
          clientData: credentialAssertion.rawClientDataJSON,
          signature: credentialAssertion.signature,
          credentialID: credentialAssertion.credentialID
        )

        submitForm(form: formAction.model, parameterOverrides: assertionParams) {

        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func processHaapiRepresentation(_ representation: HaapiRepresentation) {
        selectorViewModel = nil
        formViewModels.removeAll()
        authorizedViewModel = nil
        genericHaapiViewModel = nil

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
            } else {
                // swiftlint:disable:next line_length
                Logger.controllerFlow.debug("Ignoring new polling step: \(pollingStep.pollingProperties.status.rawValue)")
            }
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

        haapiManager = HaapiManager(haapiConfiguration: haapiConfiguration)
        oauthTokenManager = OAuthTokenManager(oauthTokenConfiguration: haapiConfiguration)

        haapiManager?.start(OAuthAuthorizationParameters(scopes: profile.selectedScopes ?? []),
                            completionHandler:
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

// MARK: Registration
struct RegistrationWebAuthN: Codable {
    let publicKey: RegistrationWebAuthnContent
}

struct RegistrationWebAuthnContent: Codable {
    // swiftlint:disable:next identifier_name
    let rp: RegistrationWebAuthNProperties
    let user: RegistrationWebAuthNUser
    let challenge: String
    let authenticatorSelection: WebAuthNAuthenticatorSelection
    let attestation: String
}

struct RegistrationWebAuthNProperties: Codable {
    let name: String
    /// RelyingPartyIdentifier - Domain
    let id: String
}

struct RegistrationWebAuthNUser: Codable {
    let name: String
    let displayName: String
    let id: String
}

struct WebAuthNAuthenticatorSelection: Codable {
    let authenticatorAttachment: String
    let requireResidentKey: Bool
    let userVerification: String
}

// MARK: AssertionRequest / Authentication

struct AssertionRequest: Codable {
    let publicKey: AssertionRequestContent
}

struct AssertionRequestContent: Codable {
    let challenge: String
    /// RelyingPartyIdentifier - Domain
    let rpId: String
    let allowCredentials: [AssertionRequestAllowCredential]
    let userVerification: String
}

struct AssertionRequestAllowCredential: Codable {
    let type: String
    let id: String
}

private extension String {
    func decodeBase64Url() -> Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // swiftlint:disable:next legacy_multiple
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return Data(base64Encoded: base64)
    }
}

private extension Data {
    func toBase64Url() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
