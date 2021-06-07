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
            if let checkboxViewModel = viewModel as? CheckboxViewModel {
                CheckboxView(checkboxViewModel.label,
                             isChecked: checkboxViewModel.boolBinding)
                    .disabled(checkboxViewModel.isReadOnly || checkboxViewModel.isDisabled)
            }
            else {
                FormTextField(viewModel.label,
                              text: viewModel.textBinding,
                              isInvalid: .constant(viewModel.invalidField != nil),
                              config: viewModel.textInputConfiguration)
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
                                                           placeholder: "foobar",
                                                           checked: nil,
                                                           readonly: false)))
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - FieldViewModel

class FieldViewModel: ObservableObject, Hashable {

    @Published var invalidField: InvalidField?
    @Published var isDisabled = false

    let field: Field
    fileprivate(set) var value: String?

    init(field: Field) {
        self.field = field
        value = field.value ?? ""
    }

    var name: String {
        return field.name
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

    final var textInputConfiguration: TextInputConfiguration {
        return field.type == .password ? .password : .default
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    static func == (lhs: FieldViewModel, rhs: FieldViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: - CheckboxViewModel

class CheckboxViewModel: FieldViewModel {
    /// An incorrect value to pass to the server. Any values except "" or `onValue` would work.
    /// With this value, the server considers a checkbox value as `false`
    private let falseValue = "NO"

    private(set) var checked = false {
        didSet {
            value = checked ? onValue : falseValue
        }
    }

    /// Reference value to pass to the server. With this value, the server considers a checkbox value as `true`.
    private let onValue: String

    override init(field: Field) {
        onValue = field.value ?? ""
        super.init(field: field)
        checked = field.checked ?? false
        if !checked {
            value = falseValue
        }
    }

    var isReadOnly: Bool {
        return field.readonly ?? false
    }

    var boolBinding: Binding<Bool> {
        Binding(get: { [unowned self] () -> Bool in
            self.checked
        }, set: { [unowned self] newValue in
            self.checked = newValue
        })
    }
}
