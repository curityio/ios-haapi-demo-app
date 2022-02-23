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
import os
import IdsvrHaapiSdk

struct SelectorView: View {
    @ObservedObject var viewModel: SelectorViewModel

    var body: some View {
        LazyVStack {
            ForEach(viewModel.options, id: \.id) { option in
                AuthenticatorButton(imageName: option.imageName,
                                    title: LocalizedStringKey(option.title))
                { btn in
                    viewModel.submitForm(form: option.formActionModel) {
                        btn.reset()
                    }
                }
                .disabled(viewModel.isProcessing)
            }
        }
        .paddingContentView([.top, .bottom])
        .onAppear(perform: {
            viewModel.isViewVisible = true
        })
        .onDisappear(perform: {
            viewModel.isViewVisible = false
        })
    }
}

// MARK: - SelectorViewModel

class SelectorViewModel: ObservableObject {
    let options: [SelectorOption]
    private weak var submitter: FlowViewModelSubmitable?
    private var observer: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    @Published var isProcessing = false
    var isViewVisible = false

    init(options: [SelectorOption],
         submitter: FlowViewModelSubmitable,
         notificationCenter: NotificationCenter = .default)
    {
        self.options = options
        self.submitter = submitter
        self.notificationCenter = notificationCenter

        observer = self.notificationCenter.addObserver(forName: FlowViewModel.isProcessingNotification,
                                                       object: nil,
                                                       queue: .main,
                                                       using:
        { [weak self] notification in
            guard self?.isViewVisible == true else { return }
            self?.isProcessing = notification.object as? Bool ?? false
        })
    }

    deinit {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
    }

    func submitForm(form: FormActionModel,
                    completionHandler: @escaping () -> Void)
    {
        submitter?.submitForm(form: form,
                              parameterOverrides: [:])
        {
            completionHandler()
        }
    }

    struct SelectorOption: Identifiable {
        var id: String {
            return title
        }

        let imageName: String
        let title: String
        let formActionModel: FormActionModel
    }
}
