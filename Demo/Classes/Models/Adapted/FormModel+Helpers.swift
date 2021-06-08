//
// Copyright (C) 2021 Curity AB.
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

extension FormModel {

    /// Returns a Boolean value indicating whether there is a `readonly` among the `fields`
    var hasReadOnlyFields: Bool {
        return fields.contains(where: { $0.readonly ?? false })
    }

    /// Returns a Boolean value indicating whether the `form` contains editable fields (`not hidden` and `not readonly`).
    var hasEditedFields: Bool {
        guard !fields.isEmpty else { return false }

        let editableFields = fields.filter { $0.readonly != true }
        let hasVisibleFields = editableFields.contains { !$0.isHidden }
        
        return hasVisibleFields
    }

    /// Returns an array of `visible` Fields. A `visible` Field is not hidden or can be readonly.
    var visibleFields: [Field] {
        return fields.filter { !$0.isHidden || ($0.readonly ?? false) }
    }

    /// Returns an array of `visible Fields` map into an array of  `FieldViewModel`.
    var visibleFieldViewModels: [FieldViewModel] {
        return visibleFields.fieldViewModels
    }
}

private extension Array where Element == Field {

    static var toFieldViewModel: (Field) -> FieldViewModel = { field in
        switch field.type {
        case .checkbox:
            return CheckboxViewModel(field: field)
        case .select:
            return OptionsViewModel(field: field)
        default:
            return FieldViewModel(field: field)
        }
    }

    var fieldViewModels: [FieldViewModel] {
        return map(Self.toFieldViewModel)
    }
}
