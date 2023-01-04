//
// Copyright (C) 2023 Curity AB.
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

extension FlowViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    @available(iOS 15.0, *) // swiftlint:disable:next cyclomatic_complexity
    func doWebauthnRegistration(registrationModel: WebAuthnRegistrationClientOperationActionModel) throws {
        // give preference to platform, else use crossplatform
        var authenticatorModel = registrationModel.platformJson
        if authenticatorModel == nil {
            authenticatorModel = registrationModel.crossPlatformJson
        }
        
        guard authenticatorModel != nil else {
            throw FlowViewModelError.invalidWebauthn
        }
        
        Logger.clientApp.debug("WebAuthn Authenticator : \(authenticatorModel.debugDescription)")
        
        webauthnAuthenticator = authenticatorModel?.authenticatorSelection?.authenticatorAttachment
        guard let challengeData = authenticatorModel?.challengeData,
              let userIdData = authenticatorModel?.userIdData,
              let rpId = authenticatorModel?.relyingPartyId,
              let userName = authenticatorModel?.userName,
              let userPreference = authenticatorModel?.authenticatorSelection?.userVerification,
              webauthnAuthenticator != nil else {
            fatalError("Invalid model registration")
        }

        var registrationRequest: ASAuthorizationRequest?
        
        // TODO: cannot use the attachment value because it may be empty for passkeys which are platform...
        // may be necessary to find another way of routing here - platform / crossplatform
        switch webauthnAuthenticator {
        case "platform":
            let credProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
            let registration = credProvider.createCredentialRegistrationRequest(challenge: challengeData,
                                                                                name: userName,
                                                                                userID: userIdData)
            if let displayName = authenticatorModel?.displayName {
                registration.displayName = displayName
            }
            
            registration.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
                rawValue: userPreference
            )
            
            if let attestationPref = authenticatorModel?.attestation {
                registration.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(
                    rawValue: attestationPref
                )
            }
            
            registrationRequest = registration
        default:
            let credProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
            let registration = credProvider.createCredentialRegistrationRequest(challenge: challengeData,
                                                                                displayName: userName,
                                                                                name: userName,
                                                                                userID: userIdData)
            
            if let displayName = authenticatorModel?.displayName {
                registration.displayName = displayName
            }
            
            if let residentKeyPref = authenticatorModel?.authenticatorSelection?.residentKey {
                registration.residentKeyPreference = ASAuthorizationPublicKeyCredentialResidentKeyPreference(
                    rawValue: residentKeyPref
                )
            }
    
            registration.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
                rawValue: userPreference
            )
            
            registration.excludedCredentials = authenticatorModel?.excludedCredentials?.map { credential in
                let credTransports = credential.transports.map { transport in
                    return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport(rawValue: transport)
                }
                
                return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: credential.id,
                                                                               transports: credTransports)
            } ?? []
            
            if let attestationPref = authenticatorModel?.attestation {
                registration.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(
                    rawValue: attestationPref
                )
            }
    
            // add public key algorithms
            var algorithmParams = [ASAuthorizationPublicKeyCredentialParameters]()
            authenticatorModel?.publicKeyCredParams?.forEach({ dictionary in
                algorithmParams.append(ASAuthorizationPublicKeyCredentialParameters(
                    algorithm: ASCOSEAlgorithmIdentifier(rawValue: dictionary.algorithmId))
                )
            })
            registration.credentialParameters = algorithmParams
            
            registrationRequest = registration
        }
        
        if let request = registrationRequest {
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    @available(iOS 15.0, *)
    func doWebauthnAssertion(data: WebAuthnAssertionClientOperationActionModel.PublicKey) {
        guard let challengeData = data.challengeData,
              let rpId = data.relyingPartyId,
              let userVerification = data.userVerificationPreference,
              let allowCredentials = data.allowCredentials
        else {
            fatalError("Invalid model for assertionModel")
        }
        
        // TODO: authenticator attachment diferentiation is not present in assertion request... necessary because of
        // the necessity of using different APIs depending on platform / crossplatform
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: rpId
        )
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)

        assertionRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
            rawValue: userVerification
        )

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

        var errorAction: Action?
        if let registrationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep {
            errorAction = registrationStep.errorActions.first
        } else if let assertionStep = pendingOperationStep as? WebAuthnAssertionClientOperationStep {
            errorAction = assertionStep.errorActions.first
        }
        
        if errorAction?.kind == ActionKind.redirect, let formAction = errorAction as? FormAction {
            submitForm(form: formAction.model, parameterOverrides: [:]) {
                self.webauthnAuthenticator = nil
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization)
    {
        if #available(iOS 15.0, *) {
            switch authorization.credential {
            case let credentialReg as ASAuthorizationPublicKeyCredentialRegistration:
                Logger.clientApp.debug("Authorization completed for registration")
                sendRegistration(credentialReg: credentialReg)
            case let assertion as ASAuthorizationPublicKeyCredentialAssertion:
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
    func sendRegistration(credentialReg: ASAuthorizationPublicKeyCredentialRegistration) {
        guard let operationStep = pendingOperationStep as? WebAuthnRegistrationClientOperationStep else {
            fatalError("Expecting a WebAuthnRegistrationClientOperationStep")
        }

        guard let formAction = operationStep.continueAction,
              let attestationObject = credentialReg.rawAttestationObject,
              let authenticatorAttachment = webauthnAuthenticator else {
            fatalError("Developer mistake")
        }

        let webauthnParameters = operationStep.formattedParametersForRegistration(
            authenticatorAttachment: authenticatorAttachment,
            attestationObject: attestationObject,
            clientData: credentialReg.rawClientDataJSON,
            credentialID: credentialReg.credentialID
        )
        
        Logger.clientApp.debug("Raw client data JSON \(credentialReg.rawClientDataJSON.toBase64Url())")
        
        submitForm(form: formAction.model, parameterOverrides: webauthnParameters) {
            self.webauthnAuthenticator = nil
        }
    }

    @available(iOS 15.0, *)
    func sendAssertion(credentialAssertion: ASAuthorizationPublicKeyCredentialAssertion) {
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

        submitForm(form: formAction.model, parameterOverrides: assertionParams) { }
    }
}
