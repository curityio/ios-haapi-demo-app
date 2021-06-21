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
import os

class FlowViewModel: ObservableObject, HaapiSubmitable {

    static let isProcessingNotification = NSNotification.Name("flowViewModel.isProcessing")

    @Published var state: HaapiState = .none
    @Published var isProcessing = false {
        didSet {
            notificationCenter.post(name: Self.isProcessingNotification,
                                    object: isProcessing)
        }
    }

    private(set) weak var controller: HaapiControllable?
    private let notificationCenter: NotificationCenter
    private var observer: NSObjectProtocol?

    private(set) var haapiStateContent: HaapiStateContent?
    private(set) var error: Error?
    private(set) var code: String?
    private(set) var tokensRepresentation: TokensRepresentation?
    private(set) var pollingStep: PollingStep?
    private(set) var messages: [Message] = []
    private(set) var links: [Link] = []
    private(set) var actions: [Action] = [] {
        didSet {
            processActions(actions)
        }
    }
    private(set) var title: String = ""
    private(set) var automaticPolling = false

    private(set) var formViewModel: FormViewModel?
    private(set) var selectorViewModel: SelectorViewModel?
    private(set) var formOptions: [FormOption]?

    init(controller: HaapiControllable,
         notificationCenter: NotificationCenter = .default)
    {
        self.controller = controller
        self.notificationCenter = notificationCenter

        observer = self.notificationCenter.addObserver(forName: HaapiController.stateNotification,
                                                       object: nil,
                                                       queue: .main)
        { [unowned self] notif in
            guard !self.isProcessing else { return } // Ignore notification when we are making the call
            guard let haapiState = notif.object as? HaapiState else { return }
            self.processState(haapiState)
        }
    }

    deinit {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
    }

    func start(_ profile: Profile,
               completionHandler: @escaping (Bool) -> Void)
    {
        guard !isProcessing else { return }

        isProcessing = true
        automaticPolling = profile.automaticPolling
        controller?.start(with: profile) { [weak self] state in
            self?.processState(state)
            if case .systemError = state {
                completionHandler(false)
            } else {
                completionHandler(true)
            }
            self?.isProcessing = false
        }
    }

    func reset() {
        resetState()
        controller?.reset()
    }

    func submitForm(form: FormModel,
                    parameterOverrides: [String: String],
                    completionHandler: HaapiCompletionHandler?)
    {
        guard !isProcessing else { return }

        isProcessing = true
        controller?.submitForm(form: form,
                               parameterOverrides: parameterOverrides,
                               completionHandler:
        { [weak self] newState in
            self?.processState(newState)
            completionHandler?(newState)
            self?.isProcessing = false
        })
    }

    func submitForm(_ form: FormModel, completion: (() -> Void)?) {
        submitForm(form: form,
                   parameterOverrides: [:])
        { _ in
            completion?()
        }
    }

    func followLink(link: Link,
                    completionHandler: HaapiCompletionHandler? = nil)
    {
        guard !isProcessing else { return }

        isProcessing = true
        controller?.followLink(link: link,
                               completionHandler:
        { [weak self] state in
            self?.processState(state)
            completionHandler?(state)
            self?.isProcessing = false
        })
    }

    func applyAction(_ action: Action) {
        isProcessing = true
        actions = [action]
        isProcessing = false
    }

    // MARK: Private

    private func processState(_ state: HaapiState) {
        switch state {
        case .systemError(let error):
            self.error = error
            pollingStep = nil
            self.state = state
        case .next(let content):
            haapiStateContent = content
            messages = content.representation.messages
            links = content.representation.links
            actions = content.actions
            let actionTitle = actions.first(where: { $0.title != nil })?.title
            title = actionTitle ?? content.representation.title ?? content.representation.type.rawValue
            pollingStep = nil
            self.state = state
        case .none:
            resetState()
        case .authorizationResponse(let code):
            messages = []
            links = []
            actions = []
            self.code = code
            self.state = state
        case .accessToken(let tokensRepresentation):
            self.tokensRepresentation = tokensRepresentation
            code = nil
            pollingStep = nil
            messages = []
            links = []
            actions = []
            title = NSLocalizedString("success_title", comment: "Title for final step in the flow")
            self.state = state
        case .polling(let pollingStep):
            messages = pollingStep.representation.messages
            links = pollingStep.representation.links
            actions = pollingStep.auxiliaryActions
            title = NSLocalizedString("polling_title", comment: "Title for polling view")
            if self.pollingStep == nil {
                self.state = state // Manual redirect
            }
            self.pollingStep = pollingStep
        default: // problem
            break
        }
    }

    private func processActions(_ actions: [Action]) {
        selectorViewModel = nil
        formViewModel = nil
        formOptions = []

        guard !actions.isEmpty else { return }

        if actions.count == 1,
           let action = actions.first
        {
            if let selectorModel = action.model as? SelectorModel {
                selectorViewModel = SelectorViewModel(options: selectorModel.options,
                                                      haapiSubmiter: self)
            }
            else if let formModel = action.model as? FormModel {
                formViewModel = FormViewModel(form: formModel,
                                              isRedirect: action.isRedirect,
                                              controller: self)
            }
            else {
                Logger.clientApp.debug("Action.model is not handled (Not a FormModel or SelectorModel)")
            }
        }
        else {
            actions.forEach {
                guard let formModel = $0.model as? FormModel else {
                    Logger.clientApp.debug("Action.model is not a FormModel(ignored)")
                    return
                }
                formOptions?.append(FormOption(title: $0.title ?? formModel.actionTitle ?? "N/A",
                                               isSimpleForm: formModel.isSimpleForm(),
                                               formModel: formModel,
                                               action: $0))
            }
        }
    }

    private func resetState() {
        state = .none
        isProcessing = false

        haapiStateContent = nil
        error = nil
        code = nil
        tokensRepresentation = nil
        pollingStep = nil
        messages = []
        links = []
        actions = []
        automaticPolling = false
    }
}

struct FormOption: Identifiable {
    let id = UUID()
    let title: String
    let isSimpleForm: Bool
    let formModel: FormModel
    let action: Action
}
