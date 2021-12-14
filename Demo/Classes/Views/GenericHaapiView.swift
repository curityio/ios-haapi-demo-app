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

import SwiftUI
import IdsvrHaapiSdk

struct GenericHaapiView: View {
    @ObservedObject var viewModel: GenericHaapiViewModel

    var body: some View {
        LazyVStack {
            if let formViewModels = viewModel.formViewModels {
                ForEach(formViewModels, id: \.self) { formViewModel in
                    FormView(formViewModel: formViewModel)
                }
            } else if let options = viewModel.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, element in
                    ColorButton(title: element) { btn in
                        viewModel.selectAt(index)
                        btn.reset()
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: GenericHaapiViewModel

class GenericHaapiViewModel: ObservableObject {

    private let genericRepresentationStep: GenericRepresentationStep
    private weak var submitter: FlowViewModelSubmitable?

    private var currentActions: [Action]

    @Published private(set) var formViewModels: [FormViewModel]?
    @Published private(set) var options: [String]?

    init(genericRepresentationStep: GenericRepresentationStep,
         submitter: FlowViewModelSubmitable)
    {
        self.genericRepresentationStep = genericRepresentationStep
        self.submitter = submitter
        currentActions = genericRepresentationStep.actions
        updateState()
    }

    func selectAt(_ index: Int) {
        guard let submitter = submitter else { return }

        if let formAction = currentActions[index] as? FormAction {
            formViewModels = [
                FormViewModel(formAction: formAction,
                              title: formAction.title?.literal,
                              fieldViewModels: [],
                              submitter: submitter)
            ]
            options = []
        } else if let selectorAction = currentActions[index] as? SelectorAction {
            currentActions = selectorAction.model.options
            updateState()
        }
    }

    private func updateState() {
        guard let submitter = submitter else { return }
        if currentActions.count == 1 {
            if let formAction = currentActions.first as? FormAction {
                formViewModels = [
                    FormViewModel(formAction: formAction,
                                  title: formAction.title?.literal,
                                  fieldViewModels: formAction.model.fields.visibleFieldViewModel,
                                  submitter: submitter)
                ]
                options = []
            }
            else if let selectorAction = currentActions.first as? SelectorAction {
                formViewModels = nil
                options = selectorAction.model.options.compactMap{ $0.title?.literal }
                currentActions = selectorAction.model.options
            }
        } else {
            let formActions = currentActions.compactMap{ $0 as? FormAction }
            if formActions.count == currentActions.count {
                formViewModels = formActions.compactMap{
                    FormViewModel(formAction: $0,
                                  title: $0.title?.literal,
                                  fieldViewModels: $0.model.fields.visibleFieldViewModel,
                                  submitter: submitter)
                }
                options = []
            }
            else {
                formViewModels = nil
                options = currentActions.compactMap{ $0.title?.literal }
            }
        }
    }
}
