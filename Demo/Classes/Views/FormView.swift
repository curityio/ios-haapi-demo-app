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

class TextState {
    var textFieldId: UUID
    @Published var text: String
    
    init(textFieldId: UUID, text: String) {
        self.textFieldId = textFieldId
        self.text = text
    }
}

class BoolState {
    var fieldId: UUID
    @Published var boolValue: Bool

    init(fieldId: UUID, boolValue: Bool) {
        self.fieldId = fieldId
        self.boolValue = boolValue
    }
}

struct FormView: View {
    @EnvironmentObject var haapiController: HaapiController
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let form: FormModel
    let action: Action

    init(
        form: FormModel,
        action: Action
    ) {
        self.form = form
        self.action = action
    }
    
    var fields: [Field] {
        form.fields.filter { !$0.isHidden }
    }
    
    var invalidFields: [InvalidField] {
        self.haapiController.currentState?.problem?.representation.invalidFields ?? []
    }

    func invalidField(for field: Field) -> InvalidField? {
        invalidFields.first(where: { $0.name == field.name || ($0.name == "terms" && field.name == "agreeToTerms" )})
    }

    func getOrMakeTextState(for field: Field) -> Binding<TextState> {
        if let index = haapiController.textFieldTextStates.firstIndex(where: { $0.textFieldId == field.uuid }) {
            return $haapiController.textFieldTextStates[index]
        } else {
            let newTextState = TextState(
                textFieldId: field.uuid,
                text: field.value ?? ""
            )
            haapiController.textFieldTextStates.append(newTextState)
            return $haapiController.textFieldTextStates[haapiController.textFieldTextStates.count-1]
        }
    }

    func getOrMakeToggleState(for field: Field) -> Binding<BoolState> {
        if let index = haapiController.toggleFieldStates.firstIndex(where: { $0.fieldId == field.uuid }) {
            return $haapiController.toggleFieldStates[index]
        } else {
            let newBoolState = BoolState(
                fieldId: field.uuid,
                boolValue: field.value != nil && field.value == "on"
            )
            haapiController.toggleFieldStates.append(newBoolState)
            return $haapiController.toggleFieldStates[haapiController.toggleFieldStates.count-1]
        }
    }
    
    var body: some View {
        VStack {
            if action.kind == "redirect" {
                Text(action.title ?? "API redirect, should be followed automatically by the client")
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: .infinity,
                        alignment: .center)
                    .padding()
            }
            ScrollView {
                ForEach(self.fields, id: \.uuid) { field in
                    FieldView(
                        field: field,
                        invalidField: invalidField(for: field),
                        fieldValue: getOrMakeTextState(for: field),
                        toggleValue: getOrMakeToggleState(for: field)
                    )
                }
            }
            
            FormButton(
                title: form.actionTitle ?? "Submit",
                form: self.form,
                willCommitState: { _ in self.presentationMode.wrappedValue.dismiss() }
            )
        }
    }
}

struct FormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // TODO: Add better example Form
            FormView(
                form: FormModel(href: "", method: ""),
                action:
                    Action(
                        template: .form,
                        kind: "login",
                        model: FormModel(href: "", method: "")
                    )
            )
        }
        .environmentObject(HaapiController())
    }
}
