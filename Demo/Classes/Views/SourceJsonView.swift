/*
 * Copyright (C) 2021 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import SwiftUI

struct SourceJsonView: View {
    let representation: Representation
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(representation.originalJson ?? "")
                    .padding()
            }
            .navigationBarTitle("Source json", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Copy") {
                    UIPasteboard.general.string = representation.originalJson ?? ""
                }
            )
        }
    }
}
