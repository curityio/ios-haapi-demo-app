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

import SwiftUI

struct FormView: View {
    @ObservedObject var formViewModel: FormViewModel

    var body: some View {
        VStack (spacing: 0) {
            if let problemViewModel = formViewModel.problemViewModel {
                ProblemView(viewModel: problemViewModel)
            }
            if let header = formViewModel.header {
                MessageView(text: header,
                            messageType: .info)
                SpacerV()
            }
            if !formViewModel.fieldViewModels.isEmpty {
                ForEach(formViewModel.fieldViewModels, id: \.self) { field in
                    FieldView()
                        .environmentObject(field)
                        .disabled(formViewModel.isProcessing)
                }
                SpacerV()
            }
            ColorButton(title: formViewModel.actionTitle,
                        buttonType: formViewModel.buttonType)
            { button in
                formViewModel.submit {
                    button.reset()
                }
            }
            .disabled(formViewModel.isProcessing)
            .opacity(formViewModel.isProcessing ? 0.7 : 1.0)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FormView_Previews: PreviewProvider {
    static var formModel = FormModel(href: "", method: "")
    static var flowViewModel = FlowViewModel(controller: HaapiController())
    static var action = Action(template: .form, kind: "", model: formModel)

    static var previews: some View {
        FormView(formViewModel: FormViewModel(form: formModel,
                                              action: action,
                                              fieldViewModels: [],
                                              flowViewModel: flowViewModel))
    }
}

struct SubmitHandler {
    var preSubmit: (() -> Void)?
    var postSubmit: HaapiCompletionHandler?
}

// MARK: - FormViewModel

class FormViewModel: NSObject, ObservableObject {

    private var form: FormModel
    private var action: Action
    private weak var flowViewModel: FlowViewModelActionnable?
    private var submitHandler: SubmitHandler?

    private var observer: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    @Published var fieldViewModels: [FieldViewModel] = []
    @Published var problemViewModel: ProblemViewModel?
    @Published var isProcessing = false

    init(form: FormModel,
         action: Action,
         fieldViewModels: [FieldViewModel],
         flowViewModel: FlowViewModelActionnable?,
         submitHandler: SubmitHandler? = nil,
         notificationCenter: NotificationCenter = .default)
    {
        self.form = form
        self.action = action
        self.fieldViewModels = fieldViewModels
        self.flowViewModel = flowViewModel
        self.submitHandler = submitHandler
        self.notificationCenter = notificationCenter

        super.init()

        observer = self.notificationCenter.addObserver(forName: FlowViewModel.isProcessingNotification,
                                                       object: nil,
                                                       queue: .main,
                                                       using:
        { [weak self] notification in
            self?.isProcessing = notification.object as? Bool ?? false
        })
    }

    deinit {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
    }

    var actionTitle: String {
        return form.actionTitle ?? "Submit"
    }

    var header: String? {
        return action.isRedirect ? form.title ?? "API redirect, should be followed automatically by the client" : nil
    }

    var buttonType: ButtonType {
        return action.buttonType
    }

    func submit(completion: (() -> Void)?) {
        submitHandler?.preSubmit?()
        
        if fieldViewModels.isEmpty && form.hasEditedFields  {
            flowViewModel?.applyAction(action)
            completion?()
        } else {
            fieldViewModels.forEach { $0.isDisabled = true }

            let notNilValues = fieldViewModels.filter { $0.value != nil }
            let parameters = notNilValues.reduce(into: [String: String]()) {
                $0[$1.name] = $1.value
            }

            flowViewModel?.submitForm(form: form,
                                      parameterOverrides: parameters,
                                      completionHandler:
            { [unowned self] result in
                switch result {
                case .problem(let problem):
                    DispatchQueue.main.async {
                        self.processProblem(problem)
                    }
                default:
                    break
                }
                submitHandler?.postSubmit?(result)
                completion?()
            })
        }
    }

    private func processProblem(_ problem: Problem) {
        if !problem.representation.invalidFields.isEmpty ||
            !problem.representation.messages.isEmpty ||
            problem.representation.type == .incorrectCredentialsProblem
        {
            let title = problem.representation.title ?? problem.representation.type.rawValue
            var messages: [Message] = problem.representation.invalidFields.compactMap {
                guard let detail = $0.detail else { return nil }
                return Message.invalid(text: detail)
            }
            messages.append(contentsOf: problem.representation.messages)
            problemViewModel = ProblemViewModel(title: title,
                                                messages: messages)
        }
        else if let title = problem.representation.title {
            problemViewModel = ProblemViewModel(title: "Error(s)",
                                                messages: [
                                                    Message(text: title,
                                                            classList: [])
                                                ])
        }
        else {
            problemViewModel = nil
        }
        
        fieldViewModels.forEach {
            $0.invalidField = nil
            $0.isDisabled = false
        }
        problem.representation.invalidFields.forEach { invalidField in
            self.fieldViewModels.first{ $0.name == invalidField.name }?.invalidField = invalidField
        }
    }
}
