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

struct PollingView: View {
    @StateObject var viewModel: PollingViewModel
    
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
            if let formViewModel = viewModel.formViewModel {
                FormView(formViewModel: formViewModel)
            }
        }
        .onDisappear {
            viewModel.invalidate()
        }
    }
}

// swiftlint:disable force_try force_unwrapping
struct PollingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PollingView(viewModel: PollingViewModel(pollingStep: pollingStep,
                                                    flowViewModel: FlowViewModel(controller: HaapiController())))
            PollingView(viewModel: PollingViewModel(pollingStep: pollingStepDone,
                                                    flowViewModel: FlowViewModel(controller: HaapiController())))
        }
        .environmentObject(FlowViewModel(controller: HaapiController()))
    }

    static var pollingStep: PollingStep {
        return PollingStep(try! Representation(Data(.pollingStep)))!
    }

    static var pollingStepDone: PollingStep {
        return PollingStep(try! Representation(Data(.pollingStepDone)))!
    }
}

class PollingViewModel: ObservableObject {

    @Published var pollingStatus: PollingStatus
    let automaticPolling: Bool
    let interval: TimeInterval

    private let scheduler = Scheduler()
    private var pollingStep: PollingStep
    private weak var flowViewModel: FlowViewModelActionnable?

    init(pollingStep: PollingStep,
         flowViewModel: FlowViewModelActionnable?,
         automaticPolling: Bool = false,
         interval: TimeInterval = 2)
    {
        self.pollingStep = pollingStep
        self.flowViewModel = flowViewModel

        self.pollingStatus = pollingStep.status
        self.automaticPolling = automaticPolling
        self.interval = interval
        schedulePolling()
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        scheduler.invalidate()
    }

    var actions: [Action]? {
        guard !pollingStep.auxiliaryActions.isEmpty else {
            return nil
        }
        return pollingStep.auxiliaryActions
    }

    var formViewModel: FormViewModel? {
        guard !pollingStep.auxiliaryActions.isEmpty else {
            return nil
        }

        let result: FormViewModel?
        if pollingStep.auxiliaryActions.count == 1,
           let action = pollingStep.auxiliaryActions.first,
           let formModel = action.model as? FormModel
        {
            result = FormViewModel(form: formModel,
                                   action: action,
                                   fieldViewModels: [],
                                   flowViewModel: flowViewModel,
                                   submitHandler: SubmitHandler(preSubmit: {
                                    self.invalidate()
                                   }, postSubmit: haapiCompletionHandler))
        } else {
            result = nil
            Logger.clientApp.debug("Actions is not handled: \(self.pollingStep.auxiliaryActions)")
        }

        return result
    }

    lazy var haapiCompletionHandler: HaapiCompletionHandler = { [unowned self] result in
        switch result {
        case .problem(let problem):
            Logger.clientApp.debug("A problem occurred when polling: \(problem)")
        case .accessToken, .step, .systemError:
            break
        case .polling(let newStep):
            if self.pollingStep != newStep {
                self.pollingStep = newStep
                self.pollingStatus = newStep.status
            } else {
                self.schedulePolling()
            }
        default:
            self.schedulePolling()
        }
    }

    func polling() {
        invalidate()

        guard pollingStatus == .pending,
              let formModel = pollingStep.pollingForm
        else {
            Logger.clientApp.error("Invalid state: \(self.pollingStatus) - cancelling polling")
            invalidate()
            return
        }
        flowViewModel?.submitForm(form: formModel,
                                  completionHandler: haapiCompletionHandler)
    }

    private func schedulePolling() {
        guard automaticPolling else { return }
        
        scheduler.schedule(withTimeInterval: interval) { [weak self] in
            self?.polling()
        }
    }
}
