//
// Copyright (C) 2020 Curity AB.
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
import os
import SwiftUI
import IdsvrHaapiSdk

struct PollingView: View {
    @ObservedObject var viewModel: PollingViewModel

    var body: some View {
        VStack {
            if viewModel.pollingStatus != .done,
               !viewModel.automaticPolling
            {
                ColorButton(title: "Poll",
                            buttonType: .secondary)
                { button in
                    viewModel.polling()
                    button.reset()
                }
                SpacerV()
            }
            if viewModel.automaticPolling, viewModel.pollingStatus == .pending {
                ArcSpinner(color: Color.spotMagenta)
            }
            FormView(formViewModel: viewModel.formViewModel)
        }
        .onDisappear {
            viewModel.invalidate()
        }
        .onAppear {
            viewModel.schedulePolling()
        }
    }
}

class PollingViewModel: ObservableObject {

    @Published var pollingStatus: PollingStatus
    let automaticPolling: Bool
    let interval: TimeInterval
    let formViewModel: FormViewModel

    private let scheduler = Scheduler()
    private var pollingStep: PollingStep
    private weak var submitter: FlowViewModelSubmitable?

    init(pollingStep: PollingStep,
         submitter: FlowViewModelSubmitable,
         automaticPolling: Bool = false,
         interval: TimeInterval = 2)
    {
        self.pollingStep = pollingStep
        self.submitter = submitter

        self.pollingStatus = pollingStep.pollingProperties.status
        self.automaticPolling = automaticPolling
        self.interval = interval

        var formAction: FormAction
        if let cancelAction = pollingStep.cancelAction {
            formAction = cancelAction
        } else {
            formAction = pollingStep.mainAction
        }

        formViewModel = FormViewModel(formAction: formAction,
                                      title: pollingStep.mainAction.title?.literal,
                                      fieldViewModels: [],
                                      submitter: submitter)
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        scheduler.invalidate()
    }

    func polling() {
        invalidate()

        submitter?.submitForm(form: pollingStep.mainAction.model,
                              parameterOverrides: [:])
        {
            DispatchQueue.main.async {
                self.schedulePolling()
            }
        }
    }

    func schedulePolling() {
        guard pollingStep.pollingProperties.status == .pending, automaticPolling else { return }

        scheduler.schedule(withTimeInterval: interval) { [weak self] in
            self?.polling()
        }
    }
}
