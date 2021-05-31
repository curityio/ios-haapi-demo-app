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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
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
                ColorButton(title: formViewModel.actionTitle) { button in
                    formViewModel.submitForm(presentationMode: presentationMode) {
                        button.reset()
                    }
                }
                .disabled(formViewModel.isProcessing)
                .opacity(formViewModel.isProcessing ? 0.7 : 1.0)
            }
            if formViewModel.isSimpleButtonVisible {
                ColorButton(title: formViewModel.actionTitle) { button in
                    formViewModel.submitForm(presentationMode: presentationMode) {
                        button.reset()
                    }
                }
                .disabled(formViewModel.isProcessing)
                .opacity(formViewModel.isProcessing ? 0.7 : 1.0)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FormView_Previews: PreviewProvider {
    static var previews: some View {
        FormView(formViewModel: FormViewModel(form: FormModel(href: "",
                                                              method: ""),
                                              isRedirect: true,
                                              controller: HaapiController()))
    }
}

// MARK: - FormViewModel

class FormViewModel: NSObject, ObservableObject {

    private var form: FormModel
    private var isRedirect: Bool
    private(set) weak var controller: HaapiSubmitable?

    private var observer: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    @Published var fieldViewModels: [FieldViewModel] = []
    @Published var problemViewModel: ProblemViewModel?
    @Published var isProcessing = false

    init(form: FormModel,
         isRedirect: Bool,
         controller: HaapiSubmitable?,
         notificationCenter: NotificationCenter = .default)
    {
        self.form = form
        self.isRedirect = isRedirect
        self.controller = controller
        self.notificationCenter = notificationCenter

        super.init()
        
        processForm(form, isRedirect: isRedirect)
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
        return isRedirect ? form.title ?? "API redirect, should be followed automatically by the client" : nil
    }

    var isSimpleButtonVisible: Bool {
        return isRedirect || form.isSimpleForm()
    }

    func submitForm(presentationMode: Binding<PresentationMode>,
                    completion: (() -> Void)?)
    {
        fieldViewModels.forEach { $0.isDisabled = true }

        let parameters = fieldViewModels.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }

        controller?.submitForm(form: form,
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
            completion?()
        })
    }

    private func processForm(_ form: FormModel,
                             isRedirect: Bool)
    {
        problemViewModel = nil
        self.form = form
        self.isRedirect = isRedirect

        let fields = form.fields.filter { !$0.isHidden }
        fieldViewModels = fields.map{ field in
            FieldViewModel(field: field)
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
                return Message(text: detail, classList: [])
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
