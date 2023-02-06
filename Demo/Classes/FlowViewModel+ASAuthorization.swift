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
    enum WebauthnAttachmentType: String {
        case platformAttachment = "platform"
        case crossPlatformAttachment = "cross-platform"
    }
    
    @available(iOS 15.0, *)
    func doWebauthnRegistration(registrationModel: WebAuthnRegistrationClientOperationActionModel,
                                attachment: WebauthnAttachmentType) {
        var authenticatorModel: WebAuthnRegistrationClientOperationActionModel.CredentialRequestOptions?
        switch attachment {
        case .platformAttachment:
            authenticatorModel = registrationModel.platformOptions
        case .crossPlatformAttachment:
            authenticatorModel = registrationModel.crossPlatformOptions
        }
        
        Logger.clientApp.debug("WebAuthn Authenticator : \(authenticatorModel.debugDescription)")
        
        selectedWebauthnAuthenticator = attachment
        guard let challengeData = authenticatorModel?.challengeData,
              let userIdData = authenticatorModel?.userIdData,
              let rpId = authenticatorModel?.relyingPartyId,
              let userName = authenticatorModel?.userName,
              let userPreference = authenticatorModel?.userVerification else {
            fatalError("Invalid model registration")
        }
        
        self.selectedWebauthnAuthenticator = attachment
        
        var registrationRequest: ASAuthorizationRequest?
        
        // when passkeys are added, it will be necessary to revise the logic
        // to find another way of routing here - platform / crossplatform / no restrictions
        switch attachment {
        case WebauthnAttachmentType.platformAttachment:
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
            
            registration.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
                rawValue: userPreference
            )
            
            if let attestationPref = authenticatorModel?.attestation {
                registration.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(
                    rawValue: attestationPref
                )
            }
            
            // swiftlint:disable:next line_length
            let crossPlatformAuthenticatorModel = authenticatorModel as? WebAuthnRegistrationClientOperationActionModel.CrossPlatformCredentialRequestOptions
            
            registration.excludedCredentials = crossPlatformAuthenticatorModel?.excludedCredentials?.map { credential in
                return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: credential.credentialID,
                                                                               transports: [])
            } ?? []
            
            // public key algorithms
            var algorithmParams = [ASAuthorizationPublicKeyCredentialParameters]()
            crossPlatformAuthenticatorModel?.publicKeyCredParams?.forEach({ dictionary in
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
    func doWebauthnAssertion(assertionModel: WebAuthnAuthenticationClientOperationActionModel,
                             attachment: WebauthnAttachmentType) {
        guard let challengeData = assertionModel.credentialOptions.challengeData,
              let rpId = assertionModel.credentialOptions.relyingPartyId,
              let userVerification = assertionModel.credentialOptions.userVerificationPreference
        else {
            fatalError("Invalid model for assertionModel")
        }
        
        selectedWebauthnAuthenticator = attachment
        
        var assertionRequest: ASAuthorizationRequest?
        switch attachment {
        case .platformAttachment:
            if let platformAllowCredentials = assertionModel.credentialOptions.platformAllowCredentials {
                
                let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                    relyingPartyIdentifier: rpId
                )
                let request = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
                
                request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
                    rawValue: userVerification
                )
                
                let allowedCredentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] =
                platformAllowCredentials.map { cred in
                    return ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: cred.credentialID)
                }
                
                request.allowedCredentials = allowedCredentials
                assertionRequest = request
            }
        case .crossPlatformAttachment:
            if let crossPlatformAllowCredentials = assertionModel.credentialOptions.crossPlatformAllowCredentials {
                let publicKeyCredentialProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(
                    relyingPartyIdentifier: rpId
                )
                let request = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
                
                request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(
                    rawValue: userVerification
                )
                
                let allowedCredentials: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor] =
                crossPlatformAllowCredentials.map { cred in
                    return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: cred.credentialID,
                                                                                   transports: [])
                }
                
                request.allowedCredentials = allowedCredentials
                assertionRequest = request
            }
        }
        
        if let request = assertionRequest {
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error)
    {
        Logger.clientApp.debug("Error for authorizationController: \(error.localizedDescription)")
        prepareWebAuthnError(canRetry: (error as NSError).code == ASAuthorizationError.Code.canceled.rawValue)
        
        // error code 1001 (ASAuthorizationError.Code.cancel) - cancel/timeout : can retry
        // error code 1004 (ASAuthorizationError.Code.failed) - not enrolled: cannot retry
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
        
        guard let attestationObject = credentialReg.rawAttestationObject,
              let authenticatorAttachment = selectedWebauthnAuthenticator,
              let credentialOptions: WebAuthnRegistrationClientOperationActionModel.CredentialRequestOptions = {
                  switch authenticatorAttachment {
                  case .platformAttachment:
                      return operationStep.actionModel.platformOptions
                  case .crossPlatformAttachment:
                      return operationStep.actionModel.crossPlatformOptions
                  }
              }() else {
                  fatalError("Developer mistake")
        }
        
        let webauthnParameters = operationStep.formattedParametersForRegistration(
            credentialOptions: credentialOptions,
            attestationObject: attestationObject,
            rawClientDataJSON: credentialReg.rawClientDataJSON,
            credentialID: credentialReg.credentialID
        )
        
        Logger.clientApp.debug("Raw client data JSON \(credentialReg.rawClientDataJSON.toBase64Url())")
        
        submitForm(form: operationStep.continueAction.model, parameterOverrides: webauthnParameters) {
            selectedWebauthnAuthenticator = nil
        }
    }
    
    @available(iOS 15.0, *)
    func sendAssertion(credentialAssertion: ASAuthorizationPublicKeyCredentialAssertion) {
        guard let operationStep = pendingOperationStep as? WebAuthnAuthenticationClientOperationStep else {
            fatalError("Expecting a WebAuthnAssertionClientOperationStep")
        }
        
        let assertionParams = operationStep.formattedParametersForAssertion(
            rawAuthenticatorData: credentialAssertion.rawAuthenticatorData,
            rawClientDataJSON: credentialAssertion.rawClientDataJSON,
            signature: credentialAssertion.signature,
            credentialID: credentialAssertion.credentialID
        )
        
        submitForm(form: operationStep.continueAction.model, parameterOverrides: assertionParams) {
            selectedWebauthnAuthenticator = nil
        }
    }
}
