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

struct ActionsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var haapiController: HaapiController

    let actions: [Action]
    var inNavigationLink: Bool
    
    @ViewBuilder
    var body: some View {
        if actions.count == 1, let action = actions.first {
            viewForAction(action, inNavigationLink: inNavigationLink)
                .navigationBarTitle(action.title ?? action.kind, displayMode: .inline)
        } else if actions.count > 1 {
            viewForActions(actions)
        } else {
            Text("No options")
        }
    }
    
    @ViewBuilder
    private func viewForAction(_ action: Action, inNavigationLink: Bool) -> some View {
        if case .selector = action.template,
           let selectorModel = action.model as? SelectorModel {
            SelectorView(
                options: selectorModel.options
            )
            .padding(.bottom, inNavigationLink ? 50 : 0)
            // FIXME: If this didn't crash the compiler, we could drop the SelectorView
//            getViewForActions(options)
        } else if let formModel = action.model as? FormModel {
            FormView(
                form: formModel,
                action: action
            )
            .padding(.bottom, inNavigationLink ? 50 : 0)

        } else {
            Text("\(String(describing: action.template))")
        }
    }
    
    @ViewBuilder
    private func viewForActions(_ actions: [Action]) -> some View {
        List {
            ForEach(actions, id: \.uuid) { action in
                if let form = action.model as? FormModel, form.isSimpleForm() {
                    ProgressRow(title: action.title ?? form.actionTitle ?? "N/A", action: { progressRow in
                        self.submitForm(form, source: progressRow)
                    })
                } else if action.model is ClientOperationModel {
                    // Don't render client-operations 
                } else {
                    NavigationLink(destination: viewForAction(action, inNavigationLink: true)) {
                        Text(action.title ?? action.kind)
                    }
                    .disabled(haapiController.transitioning)
                }
            }
        }
    }
    
    private func submitForm(_ form: FormModel, source: Resettable) {
        self.haapiController.submitForm(
            form: form,
            onError: { error in
                source.reset()
            },
            willCommitState: { state in
                if state != nil {
                    source.reset()
                }
                // Dismiss the current NavigationLink view, dropping back to the NavigationView
                self.presentationMode.wrappedValue.dismiss()
            }
        )
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ActionsView(
                    actions: [], inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                ActionsView(
                    actions: try! Representation.fromJson(RepresentationSamples.redirect).actions,
                    inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                ActionsView(
                    actions: try! Representation.fromJson(RepresentationSamples.usernamePassword).actions,
                    inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                ActionsView(
                    actions: try! Representation.fromJson(RepresentationSamples.bankidSelectSameOrOtherDevice).actions,
                    inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                ActionsView(
                    actions: try! Representation.fromJson(RepresentationSamples.selectAuthentication).actions,
                    inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                ActionsView(
                    actions: try! Representation.fromJson(RepresentationSamples.duo).actions,
                    inNavigationLink: false
                )
            }.navigationViewStyle(StackNavigationViewStyle())
        }
        .environmentObject(HaapiController())
    }

    static func actionsFrom(_ json: String) -> [Action] {
        try! Representation.fromJson(json).actions
    }
}
