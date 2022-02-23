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
import IdsvrHaapiSdk

struct FieldView: View {
    @EnvironmentObject var viewModel: FieldViewModel

    var body: some View {
        VStack (spacing: 0) {
            if let checkboxViewModel = viewModel as? CheckboxViewModel {
                CheckboxView(checkboxViewModel.label,
                             isChecked: checkboxViewModel.boolBinding,
                             checkboxSize: checkboxViewModel.checkboxSize,
                             rightCheckedImage: checkboxViewModel.rightCheckedImage)
                    .disabled(checkboxViewModel.isReadOnly || checkboxViewModel.isDisabled)
            }
            else if let optionsViewModel = viewModel as? OptionsViewModel {
                FormTextField(optionsViewModel.label,
                              text: optionsViewModel.textBinding,
                              isInvalid: .constant(viewModel.invalidField != nil),
                              options: optionsViewModel.options)
                    .disabled(viewModel.isDisabled)
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

// MARK: - FieldViewModel

class FieldViewModel: ObservableObject, Hashable {

    @Published var invalidField: InvalidInputProblem.InvalidField?
    @Published var isDisabled = false

    let field: FormField
    fileprivate(set) var value: String?

    init(field: FormField) {
        self.field = field
        if let textField = field as? TextFormField {
            value = textField.value
        } else {
            value = nil
        }
    }

    var name: String {
        return field.name
    }

    var label: String {
        return field.label?.literal ?? ""
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
        return (field is PasswordFormField) ? .password : .default
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

final class CheckboxViewModel: FieldViewModel {

    private(set) var checked = false {
        didSet {
            value = checked ? onValue : nil
        }
    }

    /// Reference value to pass to the server. With this value, the server considers a checkbox value as `true`.
    private let onValue: String

    init(checkboxField: CheckboxFormField) {
        onValue = checkboxField.value ?? ""
        super.init(field: checkboxField)
        checked = checkboxField.checked
        value = checked ? onValue : nil
    }

    var isReadOnly: Bool {
        // swiftlint:disable:next force_cast
        return (field as! CheckboxFormField).readonly
    }

    var boolBinding: Binding<Bool> {
        Binding(get: { [unowned self] () -> Bool in
            self.checked
        }, set: { [unowned self] newValue in
            self.checked = newValue
        })
    }

    var rightCheckedImage: Image? {
        guard isConsent else { return nil }

        return Image("CheckboxCheckedRight")
    }

    var checkboxSize: CGSize {
        guard isConsent else { return CGSize(width: 36, height: 36) }

        return CGSize(width: 18.5, height: 18.5)
    }

    private lazy var isConsent: Bool = {
        return field.name.hasPrefix("consent")
    }()
}

// MARK: - OptionsViewModel

final class OptionsViewModel: FieldViewModel {

    let options: [PickerOption]
    var selectedText = "" {
        didSet {
            value = options.first(where: { $0.label == selectedText })?.value
        }
    }

    init(selectField: SelectFormField) {
        options = selectField.options.map { PickerOption(value: $0.value, label: $0.label.literal) }
        super.init(field: selectField)
        let firstSelect = selectField.options.first(where: { $0.selected == true })
        value = firstSelect?.value
        selectedText = firstSelect?.label.literal ?? ""
    }

    override var textBinding: Binding<String> {
        Binding(get: { [unowned self] () -> String in
            self.selectedText
        }, set: { [unowned self] newValue in
            self.selectedText = newValue
        })
    }

    struct PickerOption: PickerOptionnable {
        let value: String
        let label: String
    }
}
