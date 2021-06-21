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

struct SelectorView: View {
    @ObservedObject var viewModel: SelectorViewModel
    
    var body: some View {
        LazyVStack {
            ForEach(viewModel.options, id: \.id) { option in
                if let form = option.model as? FormModel {
                    AuthenticatorButton(imageName: option.authenticatorTypeImageName,
                                        title: LocalizedStringKey(option.title ?? "N/A"))
                    { btn in
                        viewModel.submitForm(form: form) {
                            btn.reset()
                        }
                    }
                    .disabled(viewModel.isProcessing)
                }
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

// swiftlint:disable force_try force_cast force_unwrapping
struct SelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SelectorView(viewModel: SelectorViewModel(options: SelectorView_Previews.sampleOptions,
                                                      haapiSubmiter: HaapiController()))
        }.environmentObject(HaapiController())
    }

    static var sampleOptions: [Option] {
        return (try! Representation(Data(.selectAuthentication)).actions.first!.model as! SelectorModel).options
    }
}

// MARK: - SelectorViewModel

class SelectorViewModel: ObservableObject {
    let options: [Option]
    private let haapiSubmiter: HaapiSubmitable?
    private var observer: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    @Published var isProcessing = false
    var isViewVisible = false

    init(options: [Option],
         haapiSubmiter: HaapiSubmitable?,
         notificationCenter: NotificationCenter = .default)
    {
        self.options = options
        self.haapiSubmiter = haapiSubmiter
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

    func submitForm(form: FormModel,
                    completionHandler: @escaping () -> Void)
    {
        isProcessing = true
        haapiSubmiter?.submitForm(form: form,
                                  parameterOverrides: [:])
        { _ in
            completionHandler()
        }
    }
}
