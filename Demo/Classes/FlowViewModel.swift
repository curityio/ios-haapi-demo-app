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

protocol ApplyActionnable: AnyObject {
    /// Applies an `Action`
    func applyAction(_ action: Action)
}

/// A typealias that combines HaapiSubmitable & ApplyActionnable
typealias FlowViewModelActionnable = HaapiSubmitable & ApplyActionnable

/**
 FlowViewModel is representing a ViewModel that is aware of all HaapiState from `HaapiController`. This class interacts directly with `HaapiController`
 and has available methods to do that.

 This class is mainly used with SwiftUI. `FlowViewModel.state` and `FlowViewModel.isProcessing` are **@Published** parameters.
 With these parameters, you can be notified when a state has changed or when an interaction has been triggered.

 For UI layer and cusomization, check the viewModels or the following parameters : `FlowViewModel.messages`,
 `FlowViewModel.links`,  `FlowViewModel.title` or `FlowViewModel.imageLogo`.
 */
final class FlowViewModel: ObservableObject, FlowViewModelActionnable {

    static let isProcessingNotification = NSNotification.Name("flowViewModel.isProcessing")

    // MARK: @Published

    @Published var state: HaapiState?
    @Published var isProcessing = false {
        didSet {
            notificationCenter.post(name: Self.isProcessingNotification,
                                    object: isProcessing)
        }
    }

    // MARK: Configurations

    private var automaticPolling = false
    private weak var controller: HaapiControllable?
    private let notificationCenter: NotificationCenter
    private var observer: NSObjectProtocol?

    // MARK: Models

    private var haapiStateContent: HaapiStateContenable? {
        didSet {
            if let content = haapiStateContent {
                processActions(content.actions)
                title = content.title
                imageLogo = content.imageLogo
            } else {
                authorizedViewModel = nil
                pollingViewModel = nil
                tokensViewModel = nil
            }
        }
    }

    private(set) var error: Error?

    // MARK: Support UI

    var messages: [Message] {
        return haapiStateContent?.messages ?? []
    }

    private var problemLinks: [Link]?

    var links: [Link] {
        var results = [Link]()
        if let contentLinks = haapiStateContent?.links {
            results.append(contentsOf: contentLinks)
        }
        if let problemLinks = problemLinks {
            results.append(contentsOf: problemLinks)
        }
        return results
    }

    private(set) var title: String = ""
    private(set) var imageLogo = "Logo"

    // MARK: ViewModels

    /// A `SelectorViewModel`is generated from `[Action]`. This ViewModel is used by a `SelectorView`.
    private(set) var selectorViewModel: SelectorViewModel?
    /// A `[FormViewModel]`is generated from `[Action]`. This ViewModel is used by a `FormView`.
    private(set) var formViewModels: [FormViewModel]?
    /// A `PollingViewModel`is generated when HaapiState is `polling`. This ViewModel is used by a `PollingView`.
    private(set) var pollingViewModel: PollingViewModel?
    /// An `AuthorizedViewModel`is generated when HaapiState is `authorizationResponse`. This ViewModel is used by an `AuthorizedView`.
    private(set) var authorizedViewModel: AuthorizedViewModel?
    /// A `TokensViewModel`is generated when HaapiState is `accessToken`. This ViewModel is used by a `TokensView`.
    private(set) var tokensViewModel: TokensViewModel?

    // MARK: Init & Deinit

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

    // MARK: Callable methods

    /**
     Starts the HaapiFlow according to the provided `Profile` and invokes the `completionHandler`.
     - Parameter profile: A `Profile` that contains the configurations for Haapi.
     - Parameter completionHandler: A closure that returns a `Boolean` indicating if the call was or not a success.
     */
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

    /// Resets the HaapiFlow by clearing the internal state and notify the controller to reset itself.
    func reset() {
        resetState()
        controller?.reset()
    }

    /**
     Submits a `FormModel`with a dictionary `parameterOverrides` and invokes the `completionHandler`.
     - Parameter form: A `FormModel`
     - Parameter parametersOverrides: A dictionary of String that will override any possible keys from `FormModel`.
     - Parameter completionHAndler: A closure of `HaapiCompletionHandler` that returns an optional `HaapiState`.
     */
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

    /**
     Follows a `Link` and invokes the `completionHandler`.
     - Parameter link: A `Link`
     - Parameter completionHandler: An optional closure of `HaapiCompletionHandler` that returns an optional `HappiState`
     */
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

    /// Applies an `Action` according to the user interaction.
    func applyAction(_ action: Action) {
        isProcessing = true
        processActions([action])
        if let actionTitle = action.title {
            title = actionTitle
        }
        isProcessing = false
    }

    // MARK: Private

    /// Process the new `HaapiState` so the FlowViewModel can update its parameters and notifiy the View through the @Publisher (state)
    private func processState(_ state: HaapiState?) {
        problemLinks = nil

        switch state {
        case .systemError(let error):
            self.error = error
            self.state = state
        case .next(let content):
            haapiStateContent = content
            pollingViewModel = nil
            self.state = state
        case nil:
            resetState()
        case .authorizationResponse(let response):
            haapiStateContent = response
            authorizedViewModel = AuthorizedViewModel(authorizationCode: response.code,
                                                      controller: controller)
            self.state = state
        case .accessToken(let tokensRepresentation):
            haapiStateContent = nil
            tokensViewModel = TokensViewModel(tokensRepresentation)
            title = tokensRepresentation.title
            imageLogo = tokensRepresentation.imageLogo
            self.state = state
        case .polling(let pollingStep):
            if (haapiStateContent as? PollingStep) != pollingStep {
                pollingViewModel = PollingViewModel(pollingStep: pollingStep,
                                                    flowViewModel: self,
                                                    automaticPolling: automaticPolling)
            }
            haapiStateContent = pollingStep
            if self.state != state {
                self.state = state
            }
        case .problem(let problem):
            problemLinks = problem.links
            self.state = state
        }
    }

    /// Process the `actions` to generate the corresponding ViewModel: SelectorViewModel, FormViewModel or [FieldViewModels]
    private func processActions(_ actions: [Action]) {
        selectorViewModel = nil
        formViewModels = nil

        guard !actions.isEmpty else { return }

        if actions.count == 1,
           let action = actions.first
        {
            if let selectorModel = action.model as? SelectorModel {
                selectorViewModel = SelectorViewModel(options: selectorModel.options,
                                                      haapiSubmiter: self)
            }
            else if let formModel = action.model as? FormModel {
                formViewModels = []

                formViewModels?.append(FormViewModel(form: formModel,
                                                     action: action,
                                                     fieldViewModels: formModel.visibleFieldViewModels,
                                                     flowViewModel: self))
            }
            else {
                Logger.clientApp.debug("Action.model is not handled (Not a FormModel or SelectorModel)")
            }
        }
        else {
            formViewModels = []
            actions.forEach {
                guard let formModel = $0.model as? FormModel else {
                    Logger.clientApp.debug("Action.model is not a FormModel(ignored)")
                    return
                }

                let fieldViewModels: [FieldViewModel]

                if formModel.hasReadOnlyFields {
                    fieldViewModels = formModel.visibleFieldViewModels
                } else {
                    fieldViewModels = []
                }

                formViewModels?.append(FormViewModel(form: formModel,
                                                     action: $0,
                                                     fieldViewModels: fieldViewModels,
                                                     flowViewModel: self))
            }
        }
    }

    /// Resets the internal state of FlowViewModel
    private func resetState() {
        state = nil
        isProcessing = false

        haapiStateContent = nil
        error = nil
        automaticPolling = false
        problemLinks = nil

        selectorViewModel = nil
        formViewModels = nil
        pollingViewModel = nil
        authorizedViewModel = nil
        tokensViewModel = nil
    }
}
