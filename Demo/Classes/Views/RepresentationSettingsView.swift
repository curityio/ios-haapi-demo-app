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

struct RepresentationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var showHiddenFields: Bool
    @Binding var showParameters: Bool

    var body: some View {
        NavigationView {
            List {
                Section {
                    ToggleRow(title: "Show hidden fields", isOnValue: $showHiddenFields)
                    ToggleRow(title: "Show parameters", isOnValue: $showParameters)
                }
            }
            .navigationBarTitle("Representation settings", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct RepresentationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TwoStatefulPreviewWrapper(false, false) {
            RepresentationSettingsView(
                showHiddenFields: $0,
                showParameters: $1
            )
        }
    }
}
