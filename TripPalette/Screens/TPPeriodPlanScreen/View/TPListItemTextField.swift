import SwiftUI
import UIKit

struct TPListItemTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool
    var focusEpoch: Int
    var moveCursorToEnd: Bool
    var shouldDismissKeyboard: Bool
    var onTextChange: (String) -> Void
    var onSubmit: () -> Void
    var onBackspaceWhenEmpty: () -> Void
    var onBeganEditing: () -> Void
    var onDidMoveCursorToEnd: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> TPBackspaceTextField {
        let field = TPBackspaceTextField()
        field.delegate = context.coordinator
        field.font = .preferredFont(forTextStyle: .body)
        field.textColor = UIColor(Color.tp_textPrimary)
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.returnKeyType = .default
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        field.onBackspaceWhenEmpty = { [weak coordinator = context.coordinator] in
            coordinator?.parent.onBackspaceWhenEmpty()
        }
        return field
    }

    func updateUIView(_ uiView: TPBackspaceTextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text, !uiView.isFirstResponder || moveCursorToEnd {
            uiView.text = text
        }

        uiView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(Color.tp_textSecondary)]
        )

        if isFocused {
            let epochChanged = context.coordinator.appliedFocusEpoch != focusEpoch
            let needsFocus = !uiView.isFirstResponder || epochChanged
            guard needsFocus || moveCursorToEnd else { return }

            let epoch = focusEpoch
            let applyFocus = {
                guard context.coordinator.parent.isFocused else { return }
                context.coordinator.appliedFocusEpoch = epoch
                if !uiView.isFirstResponder {
                    // Stealing focus from another field keeps the keyboard up.
                    uiView.becomeFirstResponder()
                }
                if context.coordinator.parent.moveCursorToEnd {
                    let end = uiView.endOfDocument
                    uiView.selectedTextRange = uiView.textRange(from: end, to: end)
                    context.coordinator.parent.onDidMoveCursorToEnd()
                }
            }

            if uiView.window != nil {
                applyFocus()
            } else {
                DispatchQueue.main.async(execute: applyFocus)
            }
        } else if shouldDismissKeyboard, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TPListItemTextField
        var appliedFocusEpoch: Int = -1

        init(parent: TPListItemTextField) {
            self.parent = parent
        }

        @objc
        func editingChanged(_ textField: UITextField) {
            let value = textField.text ?? ""
            parent.text = value
            parent.onTextChange(value)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeganEditing()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }
    }
}

final class TPBackspaceTextField: UITextField {
    var onBackspaceWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        let wasEmpty = (text ?? "").isEmpty
        super.deleteBackward()
        if wasEmpty {
            onBackspaceWhenEmpty?()
        }
    }
}
