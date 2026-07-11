import SwiftUI

struct TPPlanBlockRowView: View {
    let block: TPPlanBlock
    let accentColor: Color
    let isFocused: Bool
    let focusEpoch: Int
    let moveCursorToEnd: Bool
    let shouldDismissKeyboard: Bool
    var textFieldFocus: FocusState<UUID?>.Binding
    let onTextChange: (String) -> Void
    let onURLChange: (String) -> Void
    let onDetailChange: (String) -> Void
    let onToggleTodo: () -> Void
    let onToggleExpanded: () -> Void
    let onBackspaceWhenEmpty: () -> Void
    let onSubmitListItem: () -> Void
    let onBeganEditing: () -> Void
    let onDidMoveCursorToEnd: () -> Void

    @State private var text: String
    @State private var url: String
    @State private var detail: String
    @State private var isEditingURL = false
    @FocusState private var isURLFocused: Bool

    init(
        block: TPPlanBlock,
        accentColor: Color,
        isFocused: Bool,
        focusEpoch: Int,
        moveCursorToEnd: Bool = false,
        shouldDismissKeyboard: Bool,
        textFieldFocus: FocusState<UUID?>.Binding,
        onTextChange: @escaping (String) -> Void,
        onURLChange: @escaping (String) -> Void,
        onDetailChange: @escaping (String) -> Void,
        onToggleTodo: @escaping () -> Void,
        onToggleExpanded: @escaping () -> Void,
        onBackspaceWhenEmpty: @escaping () -> Void,
        onSubmitListItem: @escaping () -> Void,
        onBeganEditing: @escaping () -> Void,
        onDidMoveCursorToEnd: @escaping () -> Void
    ) {
        self.block = block
        self.accentColor = accentColor
        self.isFocused = isFocused
        self.focusEpoch = focusEpoch
        self.moveCursorToEnd = moveCursorToEnd
        self.shouldDismissKeyboard = shouldDismissKeyboard
        self.textFieldFocus = textFieldFocus
        self.onTextChange = onTextChange
        self.onURLChange = onURLChange
        self.onDetailChange = onDetailChange
        self.onToggleTodo = onToggleTodo
        self.onToggleExpanded = onToggleExpanded
        self.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        self.onSubmitListItem = onSubmitListItem
        self.onBeganEditing = onBeganEditing
        self.onDidMoveCursorToEnd = onDidMoveCursorToEnd
        _text = State(initialValue: block.text)
        _url = State(initialValue: block.url)
        _detail = State(initialValue: block.detail)
    }

    private var isListItem: Bool {
        block.kind == .bullet || block.kind == .todo || block.kind == .toggle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                if showsLeadingControl {
                    leadingControl
                }

                VStack(alignment: .leading, spacing: 6) {
                    if isListItem {
                        TPListItemTextField(
                            text: $text,
                            placeholder: placeholder,
                            isFocused: isFocused,
                            focusEpoch: focusEpoch,
                            moveCursorToEnd: isFocused && moveCursorToEnd,
                            shouldDismissKeyboard: shouldDismissKeyboard,
                            onTextChange: onTextChange,
                            onSubmit: onSubmitListItem,
                            onBackspaceWhenEmpty: onBackspaceWhenEmpty,
                            onBeganEditing: onBeganEditing,
                            onDidMoveCursorToEnd: onDidMoveCursorToEnd
                        )
                        .frame(minHeight: 22)
                        .onChange(of: block.text) { _, newValue in
                            if text != newValue {
                                text = newValue
                            }
                        }
                    } else if block.kind == .link {
                        TPListItemTextField(
                            text: $text,
                            placeholder: placeholder,
                            isFocused: isFocused && !isURLFocused,
                            focusEpoch: focusEpoch,
                            moveCursorToEnd: isFocused && moveCursorToEnd && !isURLFocused,
                            shouldDismissKeyboard: shouldDismissKeyboard || isURLFocused,
                            onTextChange: onTextChange,
                            onSubmit: focusURLField,
                            onBackspaceWhenEmpty: onBackspaceWhenEmpty,
                            onBeganEditing: {
                                isURLFocused = false
                                onBeganEditing()
                            },
                            onDidMoveCursorToEnd: onDidMoveCursorToEnd
                        )
                        .frame(minHeight: 22)
                        .onChange(of: block.text) { _, newValue in
                            if text != newValue {
                                text = newValue
                            }
                        }
                    } else {
                        TextField(placeholder, text: $text, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(textForeground)
                            .lineLimit(1...8)
                            .focused(textFieldFocus, equals: block.id)
                            .onChange(of: text) { _, newValue in
                                onTextChange(newValue)
                            }
                            .onChange(of: textFieldFocus.wrappedValue) { _, newValue in
                                if newValue == block.id {
                                    onBeganEditing()
                                }
                            }
                    }

                    if block.kind == .link {
                        linkURLRow
                    }
                }

            }

            if block.kind == .toggle, block.isExpanded {
                TextField("Содержимое", text: $detail, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Color.tp_textPrimary)
                    .lineLimit(1...10)
                    .padding(.leading, 32)
                    .onChange(of: detail) { _, newValue in
                        onDetailChange(newValue)
                    }
            }
        }
        .padding(.vertical, 4)
    }

    private var showsLeadingControl: Bool {
        block.kind != .text
    }

    @ViewBuilder
    private var leadingControl: some View {
        switch block.kind {
        case .text:
            EmptyView()
        case .bullet:
            Text("•")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.tp_textPrimary)
                .frame(width: 22, height: 24)
        case .todo:
            Button(action: onToggleTodo) {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(block.isDone ? accentColor : Color.tp_textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: 22)
        case .toggle:
            Button(action: onToggleExpanded) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .rotationEffect(.degrees(block.isExpanded ? 90 : 0))
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: 22)
        case .link:
            Button {
                focusURLField()
            } label: {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: 22)
            .accessibilityLabel("Изменить ссылку")
        }
    }

    private func focusURLField() {
        textFieldFocus.wrappedValue = nil
        isEditingURL = true
        Task { @MainActor in
            await Task.yield()
            isURLFocused = true
        }
    }

    @ViewBuilder
    private var linkURLRow: some View {
        if let openURL = resolvedURL, !isEditingURL {
            Link(destination: openURL) {
                Text(displayURL)
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            TextField("https://…", text: $url)
                .font(.subheadline)
                .foregroundStyle(Color.tp_textSecondary)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(1)
                .focused($isURLFocused)
                .onChange(of: url) { _, newValue in
                    onURLChange(newValue)
                }
                .onChange(of: isURLFocused) { _, focused in
                    if focused {
                        isEditingURL = true
                        onBeganEditing()
                    } else {
                        isEditingURL = false
                    }
                }
        }
    }

    private var placeholder: String {
        switch block.kind {
        case .text:
            return "Текст"
        case .bullet:
            return "Пункт списка"
        case .todo:
            return "Задача"
        case .toggle:
            return "Заголовок"
        case .link:
            return "Название ссылки"
        }
    }

    private var textForeground: Color {
        if block.kind == .todo, block.isDone {
            return Color.tp_textSecondary
        }
        return Color.tp_textPrimary
    }

    private var displayURL: String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedURL: URL? {
        let trimmed = displayURL
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }
}
