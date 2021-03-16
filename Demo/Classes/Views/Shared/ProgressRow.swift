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

struct ProgressRow: View {
    var title: String
    var alignment: Alignment = .leading
    var action: ((ProgressRow) -> Void)
    
    @State private var spinnerIsActive = false
    @EnvironmentObject fileprivate var haapiController: HaapiController
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: didTapButton) {
            Text(title)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
                .overlay(
                    HStack(alignment: .center, content: {
                        Spacer()
                        if spinnerIsActive {
                            ProgressView()
                                .padding()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black)
                                )
                        }
                    })
                )
        }
        .disabled(haapiController.transitioning)
    }

    func didTapButton() {
        self.spinnerIsActive = true
        action(self)
    }
}

extension ProgressRow: Resettable {
    func reset() {
        self.spinnerIsActive = false
    }
}

struct ProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressRow(title: "Title", action: { _ in })
        }.environmentObject(HaapiController())
    }
}

