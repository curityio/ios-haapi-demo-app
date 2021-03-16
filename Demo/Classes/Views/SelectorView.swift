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
import os

struct SelectorView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var haapiController: HaapiController

    let logger = Logger()
    let options: [Option]
    
    var body: some View {
        List {
            ForEach(options, id: \.uuid) { option in
                if let form = option.model as? FormModel {
                    ProgressRow(
                        title: option.title ?? "N/A",
                        alignment: .center
                    ) { progressRow in
                        self.onSelect(form, source: progressRow)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                } else if let secondarySelector = option.model as? SelectorModel {
                    NavigationLink(
                        destination:
                            ActionsView(
                                actions: secondarySelector.options,
                                inNavigationLink: true
                            )
                    ) {
                        Text(option.title ?? "N/A")
                    }
                } else {
                    Text("N/A")
                }
            }
        }
    }
    
    private func onSelect(_ form: FormModel, source: Resettable) {
        self.haapiController.submitForm(
            form: form,
            onError: { error in
                logger.debug("Error: \(error.localizedDescription)")
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

struct SelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SelectorView(
                options: (try! Representation.fromJson(
                            RepresentationSamples.selectAuthentication)
                            .actions.first!.model as! SelectorModel).options
            )
        }.environmentObject(HaapiController())
    }
}
