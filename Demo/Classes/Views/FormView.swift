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
import HaapiModelsSDK

struct FormView: View {
    @ObservedObject var formViewModel: FormViewModel

    var body: some View {
        VStack (spacing: 0) {
            if let title = formViewModel.title {
                Text(title)
                    .font(.curityTitle2)
                SpacerV()
            }
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

// MARK: - FormViewModel

class FormViewModel: NSObject, ObservableObject {

    private var formAction: FormAction
    private weak var submitter: FlowViewModelSubmitable?

    private var observers = [NSObjectProtocol]()
    private let notificationCenter: NotificationCenter

    @Published var fieldViewModels: [FieldViewModel] = []
    @Published var problemViewModel: ProblemViewModel?
    @Published var isProcessing = false

    let title: String?

    init(formAction: FormAction,
         title: String?,
         fieldViewModels: [FieldViewModel],
         submitter: FlowViewModelSubmitable,
         notificationCenter: NotificationCenter = .default)
    {
        self.formAction = formAction
        self.fieldViewModels = fieldViewModels
        self.submitter = submitter
        self.notificationCenter = notificationCenter
        self.title = title

        super.init()

        let isProcessingNotif = self.notificationCenter.addObserver(forName: FlowViewModel.isProcessingNotification,
                                                                    object: nil,
                                                                    queue: .main,
                                                                    using:
        { [weak self] notification in
            self?.isProcessing = notification.object as? Bool ?? false
        })
        observers.append(isProcessingNotif)

        let problemNotif = self.notificationCenter.addObserver(forName: FlowViewModel.problemRepresentationNotification,
                                                               object: nil,
                                                               queue: .main)
        { [weak self] notification in
            guard let problem = notification.object as? ProblemRepresentation else { return }
            self?.processProblem(problem)
        }
        observers.append(problemNotif)
    }

    deinit {
        observers.forEach { notificationCenter.removeObserver($0) }
        observers.removeAll()
    }

    var actionTitle: String {
        return formAction.model.actionTitle?.value() ?? "Submit"
    }

    var header: String? {
        guard formAction.kind == .redirect else {
            return nil
        }
        return "API redirect, should be followed automatically by the client"
    }

    var buttonType: ButtonType {
        return formAction.kind == .cancel ? .secondary : .primary
    }

    func submit(completion: @escaping () -> Void) {
        fieldViewModels.forEach { $0.isDisabled = true }

        let notNilValues = fieldViewModels.filter { $0.value != nil }
        let parameters = notNilValues.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
        submitter?.submitForm(form: formAction.model,
                              parameterOverrides: parameters)
        {
            completion()
        }
    }

    private func processProblem(_ problem: ProblemRepresentation) {
        guard !fieldViewModels.isEmpty else { return }
        fieldViewModels.forEach {
            $0.isDisabled = false
            $0.invalidField = nil
        }

        var problemMessageBundle = problem.messages.map {
            ProblemMessageBundle(text: $0.text.value(),
                                 messageType: $0.messageType)
        }

        guard let invalidInputProblem = problem as? InvalidInputProblem else {
            problemViewModel = ProblemViewModel(title: problem.title,
                                                messages: problemMessageBundle)
            return
        }

        invalidInputProblem.invalidFields.forEach { invalidField in
            problemMessageBundle.append(ProblemMessageBundle(text: invalidField.detail, messageType: .error))
            self.fieldViewModels.first { $0.name == invalidField.name }?.invalidField = invalidField
        }

        problemViewModel = ProblemViewModel(title: problem.title,
                                            messages: problemMessageBundle)
    }
}
