/*
 * Copyright (C) 2020 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import SwiftUI

enum PresentedModal: String, HashIdentifiable {
    case settings
    case pageSettings
}

struct MainView: View {
    @ObservedObject var haapiController: RuntimeHaapiController
    @State var presentedModal: PresentedModal?
    @EnvironmentObject var globalSettings: GlobalSettings
    @State var isLoading = false

    var body: some View {
        Group {
            if let haapiState = haapiController.currentState {
                StateView(
                    haapiState: haapiState
                )
            } else {
                StartAuthView(
                    isLoading: $isLoading,
                    startAction: { button in
                        isLoading = true
                        haapiController.start(
                            onError: { error in
                                button.reset()
                                self.onError(error)
                            },
                            willCommitState: { state in
                                if state != nil {
                                    button.reset()
                                }
                                self.onSuccess(state: state)
                            }
                        )
                    },
                    settingsAction: {
                        presentedModal = .settings
                    }
                )
            }
        }
        .environmentObject(haapiController as HaapiController)
        .sheet(item: $presentedModal, content: { item in
            if item == .settings {
                GlobalSettingsView()
                    .environmentObject(globalSettings)
            }
        })
        .alert(isPresented: $haapiController.isDisplayingErrorDialog, content: {
            Alert(
                title: Text("Client error"),
                message: Text(haapiController.displayingErrorMessage),
                dismissButton: .default(Text("Ok"))
            )
        })
    }

    private func onSuccess(state: HaapiState?) {
        isLoading = false
    }

    private func onError(_ error: Error) {
        haapiController.showErrorDialog(withMessage: String(describing: error))
        isLoading = false
        print("Error: \(String(describing: error))")
    }
}

struct StartAuthView: View {
    @Binding var isLoading: Bool
    var startAction: (ColorButton) -> Void
    var settingsAction: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                ColorButton(
                    title: "Start Authentication",
                    action: startAction)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: settingsAction) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StartAuthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatefulPreviewWrapper(false) {
                StartAuthView(isLoading: $0, startAction: { _ in }, settingsAction: { })
            }
        }
    }
}
