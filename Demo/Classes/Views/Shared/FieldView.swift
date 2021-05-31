//
// Copyright (C) 2020 Curity AB.
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

import SwiftUI

struct FieldView: View {
    @EnvironmentObject var viewModel: FieldViewModel
    
    var body: some View {
        VStack (spacing: 0) {
            if viewModel.type == .password {
                FormTextField(viewModel.label,
                              text: viewModel.textBinding,
                              isInvalid: .constant(viewModel.invalidField != nil),
                              config: .password)
                    .disabled(viewModel.isDisabled)
            } else if viewModel.type == .checkbox {
                CheckboxView(viewModel.label,
                             isChecked: viewModel.boolBinding)
                    .disabled(viewModel.isDisabled)
            } else {
                FormTextField(viewModel.label,
                              text: viewModel.textBinding,
                              isInvalid: .constant(viewModel.invalidField != nil),
                              config: .default)
                    .disabled(viewModel.isDisabled)
            }
        }
    }
}

struct FieldView_Previews: PreviewProvider {
    static var previews: some View {
        FieldView()
            .environmentObject(FieldViewModel(field: Field(name: "Password",
                                                           type: .password,
                                                           label: "Password",
                                                           value: "",
                                                           placeholder: "foobar")))
        .previewLayout(.sizeThatFits)
    }
}

class FieldViewModel: ObservableObject, Hashable {

    @Published var invalidField: InvalidField?
    @Published var isDisabled = false

    let field: Field
    private(set) var value: String

    private enum Constants {
        static let onValue = "on" // true
        static let offValue = "off" // false
    }

    init(field: Field) {
        self.field = field
        value = field.value ?? ""
    }

    var name: String {
        return field.name
    }

    var type: FieldType {
        return field.type
    }

    var label: String {
        return field.label ?? ""
    }

    var textBinding: Binding<String> {
        Binding(get: { [weak self] () -> String in
            self?.value ?? ""
        }, set: { [weak self] newValue in
            self?.value = newValue
        })
    }

    var isInvalid: Bool {
        return invalidField != nil
    }

    // checkbox
    var isOn: Bool {
        return field.value == Constants.onValue
    }

    var boolBinding: Binding<Bool> {
        Binding(get: { [weak self] () -> Bool in
            self?.value == Constants.onValue
        }, set: { [weak self] newValue in
            self?.value = newValue ? Constants.onValue : Constants.offValue
        })
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    static func == (lhs: FieldViewModel, rhs: FieldViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
