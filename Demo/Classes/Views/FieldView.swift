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

struct FieldView: View {
    @EnvironmentObject var haapiController: HaapiController
    var field: Field
    var invalidField: InvalidField?
    @Binding var fieldValue: TextState
    @Binding var toggleValue: BoolState
    
    var body: some View {
        VStack {
            Text(field.label ?? "")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 14, weight: .light))
            let isInvalid = invalidField != nil
            if field.type == .password {
                SecureField(field.placeholder ?? field.name, text: $fieldValue.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(isInvalid ? Color.red: Color.gray, lineWidth: 1)) // FIXME: Create custom TextFieldStyle instead of using overlay?
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(self.haapiController.transitioning)
            } else if field.type == .checkbox {
                Toggle(field.label ?? "", isOn: $toggleValue.boolValue)
                    .disabled(self.haapiController.transitioning)
            } else {
                TextField(field.placeholder ?? field.name, text: $fieldValue.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(isInvalid ? Color.red: Color.gray, lineWidth: 1))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(self.haapiController.transitioning)
            }
            if let invalidField = invalidField {
                Text(invalidField.detail ?? invalidField.reason ?? "*")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

struct FieldView_Previews: PreviewProvider {
    static var previews: some View {
        TwoStatefulPreviewWrapper(TextState(textFieldId: UUID(), text: ""), BoolState(fieldId: UUID(), boolValue: false)) {
            FieldView(
                field: Field(name: "Password", type: .password, label: "Password", value: "", placeholder: "foobar"),
                invalidField: nil,
                fieldValue: $0,
                toggleValue: $1
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
