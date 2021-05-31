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

import Foundation
import SwiftUI
import UIKit

struct CTextField: UIViewRepresentable {
    let placeholder: String?
    @Binding var text: String
    let textConfiguration: TextInputConfiguration
    let editingHandler: ((Bool) -> Void)?

    var isSecureTextEntry = false
    var isInvalid = false

    init(placeholder: String?,
         text: Binding<String>,
         textConfiguration: TextInputConfiguration = .default,
         editingHandler: ((Bool) -> Void)? = nil)
    {
        self.placeholder = placeholder
        self._text = text
        self.textConfiguration = textConfiguration
        self.editingHandler = editingHandler
    }

    // MARK: UIViewRepresentable

    typealias UIViewType = UITextField

    func makeUIView(context: Context) -> UITextField {
        let textField = CurityTextField()
        textField.font = UIFont.text
        textField.textColor = isInvalid ? UIColor(Color.error) : UIColor(Color.formLabels)
        textField.text = text
        textField.adjustsFontForContentSizeCategory = true
        let attributedStrings = [
            NSAttributedString.Key.font: UIFont.text,
            NSAttributedString.Key.foregroundColor: UIColor(.greyPlaceholder)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder ?? "",
                                                             attributes: attributedStrings)

        textField.delegate = context.coordinator
        textField.applyTextInputConfiguration(textConfiguration)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.textColor = isInvalid ? UIColor(Color.error) : UIColor(Color.formLabels)
        uiView.isSecureTextEntry = isSecureTextEntry
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self,
                    editingHandler: editingHandler)
    }

    static func dismantleUIView(_ uiView: UITextField, coordinator: Coordinator) {
        uiView.inputAccessoryView = nil
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        private let cTextField: CTextField
        private let editingHandler: ((Bool) -> Void)?

        var isEditing = false

        weak var nextFocus: UIResponder? {
            didSet {
                nextButtonItem.isEnabled = nil != nextFocus
            }
        }

        weak var previousFocus: UIResponder? {
            didSet {
                previousButtonItem.isEnabled = nil != previousFocus
            }
        }

        private lazy var toolBar: UIToolbar = {
            let toolBar = UIToolbar(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: Double(UIScreen.main.bounds.width),
                                                  height: 50.0))
            toolBar.barStyle = .default
            toolBar.items = [
                previousButtonItem,
                nextButtonItem,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                closeButtonItem
            ]
            toolBar.sizeToFit()
            return toolBar
        }()

        private lazy var previousButtonItem: UIBarButtonItem = {
            let image = UIImage(systemName: "arrow.up")
            let button = UIBarButtonItem(image: image,
                                         style: .plain,
                                         target: self,
                                         action: #selector(previousButtonAction(sender:)))

            return button
        }()

        private lazy var nextButtonItem: UIBarButtonItem = {
            let image = UIImage(systemName: "arrow.down")
            let button = UIBarButtonItem(image: image,
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextButtonAction(sender:)))

            return button
        }()

        private lazy var closeButtonItem: UIBarButtonItem = {
            let image = UIImage(systemName: "keyboard.chevron.compact.down")
            let button = UIBarButtonItem(image: image,
                                         style: .plain,
                                         target: self,
                                         action: #selector(closeButtonAction))
            return button
        }()

        init(_ cTextField: CTextField,
             editingHandler: ((Bool) -> Void)?)
        {
            self.cTextField = cTextField
            self.editingHandler = editingHandler
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            isEditing = true
            nextFocus = textField.nextControlResponder()
            previousFocus = textField.nextControlResponder(isPrevious: true)
            if nextFocus != nil {
                textField.returnKeyType = .next
            }
            textField.inputAccessoryView = toolBar
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            editingHandler?(true)
            
            return true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isEditing = false
            textField.removeTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            editingHandler?(false)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if let nextFocus = nextFocus {
                nextFocus.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }

            return true
        }

        // MARK: Actions

        @objc private func textFieldDidChange(_ textField: UITextField) {
            cTextField.text = textField.text ?? ""
        }

        @objc private func closeButtonAction() {
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        @objc private func nextButtonAction(sender: UIBarButtonItem) {
            nextFocus?.becomeFirstResponder()
        }

        @objc private func previousButtonAction(sender: UIBarButtonItem) {
            previousFocus?.becomeFirstResponder()
        }
    }
}

// MARK: - CTextField modifiers

extension CTextField {

    func hidePassword(_ value: Bool) -> CTextField {
        var modifier = self
        modifier.isSecureTextEntry = value
        return modifier
    }

    func isInvalid(_ value: Bool) -> CTextField {
        var modifier = self
        modifier.isInvalid = value
        return modifier
    }
}

// MARK: - Configuration for TextField

struct TextInputConfiguration: Equatable {

    let textContentType: UITextContentType?
    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let smartDashsesType: UITextSmartDashesType
    let smartInsertDeleteType: UITextSmartInsertDeleteType
    let smartQuotesType: UITextSmartQuotesType
    let spellCheckingType: UITextSpellCheckingType
    let keyboardType: UIKeyboardType
    let keyboardAppearance: UIKeyboardAppearance
    let returnKeyType: UIReturnKeyType
    let enablesReturnKeyAutomatically: Bool
    let isSecureTextEntry: Bool
}

extension TextInputConfiguration {

    static var `default`: TextInputConfiguration {
        TextInputConfiguration(textContentType: nil,
                               autocapitalizationType: .none,
                               autocorrectionType: .no,
                               smartDashsesType: .default,
                               smartInsertDeleteType: .default,
                               smartQuotesType: .default,
                               spellCheckingType: .no,
                               keyboardType: .default,
                               keyboardAppearance: .default,
                               returnKeyType: .default,
                               enablesReturnKeyAutomatically: true,
                               isSecureTextEntry: false)
    }

    static var url: TextInputConfiguration {
        TextInputConfiguration(textContentType: .URL,
                               autocapitalizationType: .none,
                               autocorrectionType: .no,
                               smartDashsesType: .default,
                               smartInsertDeleteType: .default,
                               smartQuotesType: .no,
                               spellCheckingType: .no,
                               keyboardType: .URL,
                               keyboardAppearance: .default,
                               returnKeyType: .default,
                               enablesReturnKeyAutomatically: true,
                               isSecureTextEntry: false)
    }

    static var password: TextInputConfiguration {
        TextInputConfiguration(textContentType: .password,
                               autocapitalizationType: .none,
                               autocorrectionType: .no,
                               smartDashsesType: .default,
                               smartInsertDeleteType: .default,
                               smartQuotesType: .no,
                               spellCheckingType: .no,
                               keyboardType: .default,
                               keyboardAppearance: .default,
                               returnKeyType: .default,
                               enablesReturnKeyAutomatically: true,
                               isSecureTextEntry: true)
    }
}

private extension UITextField {

    func applyTextInputConfiguration(_ config: TextInputConfiguration) {
        textContentType = config.textContentType
        autocapitalizationType = config.autocapitalizationType
        autocorrectionType = config.autocorrectionType
        smartDashesType = config.smartDashsesType
        smartInsertDeleteType = config.smartInsertDeleteType
        smartQuotesType = config.smartQuotesType
        spellCheckingType = config.spellCheckingType
        keyboardType = config.keyboardType
        keyboardAppearance = config.keyboardAppearance
        returnKeyType = config.returnKeyType
        enablesReturnKeyAutomatically = config.enablesReturnKeyAutomatically
        isSecureTextEntry = config.isSecureTextEntry
    }
}

// MARK: - UITextField

extension UITextField {

    // swiftlint:disable:next cyclomatic_complexity
    func nextControlResponder(isPrevious: Bool = false) -> UIResponder? {
        var foundRefView = false
        var rootView: UIView = self
        var found: UIResponder?
        while !foundRefView {
            if let nextView = rootView.next as? UIView {
                if String(describing: type(of: nextView)).lowercased().contains("scrollview") {
                    foundRefView = true
                } else {
                    rootView = nextView
                }
            } else {
                foundRefView = true
            }
        }

        var foundSelf = false
        if rootView.subviews.count == 1,
           let tableView = rootView.subviews.first?.subviews.first as? UITableView
        {
            // TableView
            let sortedBy: (UIView, UIView) -> Bool = {
                if isPrevious {
                    return $0.frame.origin.y > $1.frame.origin.y
                } else {
                    return $0.frame.origin.y < $1.frame.origin.y
                }
            }
            for cell in tableView.subviews.sorted(by: sortedBy) {
                if found != nil {
                    break
                }
                if let midElem = cell.subviews.last,
                   let candidates = midElem.subviews.first?.subviews
                {
                    for candidate in candidates {
                        if let element = candidate.subviews.first {
                            if foundSelf, !(element is UISwitch) {
                                found = element
                            } else {
                                foundSelf = element == self
                            }
                            break
                        }
                    }
                }
            }
        } else {
            // ScrollView
            let rootSubViews = isPrevious ? rootView.subviews.reversed() : rootView.subviews
            for subview in rootSubViews {
                let childrenView = subview.subviews
                if let firstChild = childrenView.first {
                    if foundSelf, let next = firstChild.subviews.first {
                        found = next
                        break
                    } else if firstChild.contains(self) {
                        foundSelf = true
                    }
                }
            }
        }

        return found
    }
}

// MARK: UITextField subclass

private class CurityTextField: UITextField {

    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }

    override func becomeFirstResponder() -> Bool {
        let isFirstResponder = super.becomeFirstResponder()
        if isFirstResponder, isSecureTextEntry {
            let originalText = text
            text?.removeAll()
            insertText(originalText ?? "")
        }

        return isFirstResponder
    }
}
