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

import UIKit
import SwiftUI
import os

extension View {

    /// Custom configuration for navigationBar by using UIKit. The handler will be executed in viewDidLayoutSubviews()
    func configureNavigationBar(_ configureHandler: @escaping (UINavigationController) -> Void) -> some View {
        modifier(NavigationViewModifier(configureHandler: configureHandler))
    }
}

// MARK: Objc wrapper for SwiftUI

private struct NavigationViewModifier: ViewModifier {
    let configureHandler: (UINavigationController) -> Void

    func body(content: Content) -> some View {
        content.background(NavigationConfigurator(configureHandler: configureHandler))
    }
}

private struct NavigationConfigurator: UIViewControllerRepresentable {
    let configureHandler: (UINavigationController) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        NavigationConfiguratorVC(configureHandler)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

private class NavigationConfiguratorVC: UIViewController {
    let configure: (UINavigationController) -> Void

    init(_ configure: @escaping (UINavigationController) -> Void) {
        self.configure = configure
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let navigationCtrl = navigationController else {
            Logger.clientApp.debug("NavigationController is not present... check the view hierarchy")
            return
        }
        configure(navigationCtrl)
    }
}
