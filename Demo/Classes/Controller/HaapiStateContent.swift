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

protocol HaapiStateContentable {
    /// The Haapi Representation
    var representation: Representation { get }
    /// The array of actions of the Representation
    var actions: [Action] { get }

    /// The title that can be used in your View. It is based on the Representation or [Actions] or Representation.Type.
    var title: String { get }
    /// The image name for building an UIImage(UIKit) or Image(SwiftUI) from your assetFolder.
    var imageLogo: String { get }
}

extension HaapiStateContentable {

    /// The array of messages of the Representation
    var messages: [Message] {
        return representation.messages
    }

    /// The array of links of the Representation
    var links: [Link] {
        return representation.links
    }

    /// The Representation type
    var type: RepresentationType {
        return representation.type
    }

    var title: String {
        return actions.first(where: { $0.title != nil })?.title ?? representation.type.rawValue
    }

    var imageLogo: String {
        return representation.type.imageLogo
    }
}
/// A model representing the latest received Haapi Representation with relevent parameters, functions and methods to be consumed directly
/// with a ViewModel or View.
struct HaapiStateContent: HaapiStateContentable, Equatable {
    let representation: Representation
    let actions: [Action]

    init(representation: Representation,
         continueActions: [Action])
    {
        self.representation = representation
        self.actions = continueActions
    }

    static func == (lhs: HaapiStateContent, rhs: HaapiStateContent) -> Bool {
        return lhs.representation == rhs.representation
            && lhs.actions == rhs.actions
    }
}

enum HaapiState: Equatable, CustomStringConvertible {
    /// The flow is interrupted due to a system Error
    case systemError(Error)
    /// A new step that is not a problem/error/polling/authorizationResponse or accessToken; A HaapiStateContent is provided.
    case step(HaapiStateContent)
    /// A problem from a representation
    case problem(Problem)
    /// The authorization code
    case authorizationResponse(AuthorizationContent)
    /// The accessToken response; Final step
    case accessToken(OAuthTokenResponse)
    /// PollingStep
    case polling(PollingStep)

    static func == (lhs: HaapiState, rhs: HaapiState) -> Bool {
        switch (lhs, rhs) {
        case (.systemError(let err1 as NSError), .systemError(let err2 as NSError)):
            return err1 == err2
        case (.problem(let prob1), .problem(let prob2)):
            return prob1 == prob2
        case (.authorizationResponse(let code1), .authorizationResponse(let code2)):
            return code1 == code2
        case (.step(let content1), .step(let content2)):
            return content1 == content2
        case (.accessToken(let dict1), .accessToken(let dict2)):
            return dict1 == dict2
        case (.polling(let step1), .polling(let step2)):
            return step1 == step2
        default:
            return false
        }
    }

    var description: String {
        let result: String
        switch self {
        case .systemError:
            result = "systemError"
        case .step:
            result = "next"
        case .problem:
            result = "problem"
        case .authorizationResponse:
            result = "authorizationResponse"
        case .accessToken:
            result = "accessToken"
        case .polling:
            result = "polling"
        }

        return result
    }
}
