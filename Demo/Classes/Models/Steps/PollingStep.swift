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

/// An enum representing the status of `PollingStep`.
enum PollingStatus: CustomStringConvertible {
    case pending
    case done
    case failed
    case unknown

    var description: String {
        switch self {
        case .pending:
            return "pending"
        case .done:
            return "done"
        case .failed:
            return "failed"
        case .unknown:
            return "unknown"
        }
    }
}

/**
 A model representing `HaapiState.pollingStep`.

 Polling step requires a client to poll using one of the provided actions. The client may use a polling interval of its choosing, usually a few seconds. While polling, the client should display any links or messages provided in the response from the server, as well as a visual indicator to make it clear that the server is performing some work while waiting for some external action to be completed.
 */
struct PollingStep: HaapiStateContentable, Equatable {
    let representation: Representation
    let actions: [Action]
    
    init?(_ representation: Representation) {
        guard representation.type == .pollingStep else {
            return nil
        }

        self.representation = representation
        self.actions = representation.actions
    }

    var title: String {
        return NSLocalizedString("polling_title",
                                 comment: "Title for polling view")
    }

    static func == (lhs: PollingStep, rhs: PollingStep) -> Bool {
        return lhs.representation == rhs.representation
            && lhs.actions == rhs.actions
            && lhs.status == rhs.status
    }
}

extension PollingStep {

    /// The status for PollingStep.
    var status: PollingStatus {
        let status = representation.properties["status"]

        if status == "done" {
            return .done
        } else if status == "pending" {
            return .pending
        } else if status == "failed" {
            return .failed
        }

        return .unknown
    }

    /// The potential `FormModel` of the Representation.
    var formModel: FormModel? {
        let result: FormModel?

        switch status {
        case .pending:
            if let pollForm = representation.pollForm {
                result = pollForm
            } else if let cancelForm = representation.cancelForm {
                result = cancelForm
            } else {
                result = nil
            }
        case .done, .failed:
            if let redirectForm = representation.redirectForm {
                result = redirectForm
            } else if let form = representation.formModel {
                result = form
            } else {
                result = nil
            }
        case .unknown:
            result = nil
        }

        return result
    }

    var pollingForm: FormModel? {
        return representation.pollForm
    }

    var cancelForm: FormModel? {
        return representation.cancelForm
    }

    /// The actions of the Representation according to the PollingStep.status
    var auxiliaryActions: [Action] {
        actions
            .filter { action in
                guard action.title != nil else { return false }
                switch status {
                case .done:
                    return action.kind != "redirect"
                case .pending:
                    return action.kind != "poll" || action.kind != "cancel"
                default:
                    return true
                }
            }
    }
}
