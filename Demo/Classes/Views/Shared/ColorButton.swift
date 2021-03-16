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

struct ColorButton: View {
    let title: String
    let color: Color
    fileprivate var action: ((ColorButton) -> Void)
    @State private var spinnerIsActive = false
    @EnvironmentObject fileprivate var haapiController: HaapiController

    init(
        title: String,
        color: Color = .blue,
        action: @escaping ((ColorButton) -> Void) = { _ in }
    ) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: didTapButton) {
            Text(title)
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .padding(12)
                .overlay(
                    HStack(alignment: .center, content: {
                        Spacer()
                        if spinnerIsActive {
                            ProgressView()
                                .padding()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .white)
                                )
                        }
                    })
                )
        }
        .background(color)
        .cornerRadius(20)
        .padding([.leading, .trailing])
        .padding([.top, .bottom], 8)
        .opacity(!haapiController.transitioning ? 1 : 0.7)
        .disabled(haapiController.transitioning)
    }

    func didTapButton() {
        self.spinnerIsActive = true
        action(self)
    }
}

extension ColorButton: Resettable {
    func reset() {
        self.spinnerIsActive = false
    }
}

struct FormButton: View {
    let title: String
    let color: Color
    let form: FormModel
    let willCommitState: OnCommitState
    @EnvironmentObject fileprivate var haapiController: HaapiController
    let logger = Logger()
    
    init(
        title: String,
        color: Color = .blue,
        form: FormModel,
        willCommitState: @escaping OnCommitState
    ) {
        self.title = title
        self.color = color
        self.form = form
        self.willCommitState = willCommitState
    }
    
    var body: some View {
        ColorButton(
            title: title,
            color: color,
            action: { button in
                submitForm(button: button)
            }
        )
    }
    
    private func submitForm(button: ColorButton) {
        haapiController.submitForm(
            form: form,
            onError: { error in
                button.reset()
                self.logger.debug("Error: \(error.localizedDescription)")
            },
            willCommitState: { state in
                if state != nil {
                    button.reset()
                }
                self.willCommitState(state)
            }
        )
    }
}

struct ColorButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ColorButton(title: "Title", action: { _ in })
        }.environmentObject(HaapiController())
    }
}
