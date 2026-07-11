import ElegantEmojiPicker
import SwiftUI
import UIKit

struct TPPeriodEditorView: View {
    enum Mode: Equatable {
        case create(datesCount: Int)
        case edit(TPPeriodEditSession)
    }

    let mode: Mode
    let onCreate: (String?, String?, Color) -> Void
    let onUpdate: (UUID, String?, String?, Color) -> Void
    let onDelete: (UUID) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var emoji = ""
    @State private var selectedEmoji: Emoji?
    @State private var selectedColor: Color = TPPeriodPalette.default.color
    @State private var selectedPeriodID: UUID?
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var isEmojiPickerPresented = false

    var body: some View {
        NavigationStack {
            Form {
                if case let .edit(session) = mode, session.isMultiple {
                    Section("Периоды на этом дне") {
                        ForEach(session.periods) { period in
                            Button {
                                selectPeriod(period)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(period.color)
                                        .frame(width: 16, height: 16)
                                    Text(periodDisplayName(period))
                                        .foregroundStyle(Color.tp_textPrimary)
                                    Spacer()
                                    if selectedPeriodID == period.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.tp_tint)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        TextField("Название (необязательно)", text: $title)
                            .foregroundStyle(Color.tp_textPrimary)

                        Button {
                            isEmojiPickerPresented = true
                        } label: {
                            if emoji.isEmpty {
                                Image(systemName: "face.smiling")
                                    .font(.title3)
                                    .foregroundStyle(Color.tp_textSecondary)
                            } else {
                                Text(emoji)
                                    .font(.title2)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Выбрать emoji")
                    }
                } header: {
                    Text("Направление")
                } footer: {
                    Text(datesInfoText)
                }

                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(TPPeriodPalette.colors) { swatch in
                            Circle()
                                .fill(swatch.color)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if TPPeriodPalette.matches(selectedColor, swatch.color) {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = swatch.color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if case .edit = mode {
                    Section {
                        Button("Удалить период", role: .destructive) {
                            if let selectedPeriodID {
                                onDelete(selectedPeriodID)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.tp_backgroundSecondary)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle, action: save)
                }
            }
            .onAppear(perform: configureInitialValues)
            .onChange(of: editPeriodIDs) { _, ids in
                guard case let .edit(session) = mode else { return }
                if selectedPeriodID == nil || selectedPeriodID.map({ !ids.contains($0) }) == true {
                    selectedPeriodID = ids.first
                    if let period = session.periods.first(where: { $0.id == selectedPeriodID }) {
                        apply(period)
                    }
                }
            }
            .onChange(of: selectedPeriodID) { _, _ in
                if case let .edit(session) = mode,
                   let id = selectedPeriodID,
                   let period = session.periods.first(where: { $0.id == id }) {
                    apply(period)
                }
            }
            .onChange(of: selectedEmoji) { _, newValue in
                if let newValue {
                    emoji = newValue.emoji
                } else if isEmojiPickerPresented {
                    emoji = ""
                }
            }
        }
        .presentationDetents(presentationDetents, selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .emojiPicker(
            isPresented: $isEmojiPickerPresented,
            selectedEmoji: $selectedEmoji,
            configuration: ElegantConfiguration(showRandom: false),
            localization: ElegantLocalization(
                searchFieldPlaceholder: "Поиск emoji",
                searchResultsTitle: "Результаты",
                searchResultsEmptyTitle: "Ничего не найдено",
                randomButtonTitle: "Случайный"
            )
        )
        .onAppear {
            if case .edit = mode {
                selectedDetent = .fraction(0.72)
            }
        }
    }

    private var presentationDetents: Set<PresentationDetent> {
        if case .edit = mode {
            return [.fraction(0.72), .large]
        }
        return [.medium, .large]
    }

    private var editPeriodIDs: [UUID] {
        if case let .edit(session) = mode {
            return session.periods.map(\.id)
        }
        return []
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "Новый период"
        case let .edit(session):
            return session.isMultiple ? "Периоды" : "Период"
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .create:
            return "Сохранить"
        case .edit:
            return "Обновить"
        }
    }

    private var datesInfoText: String {
        switch mode {
        case let .create(datesCount):
            return "Выбрано дней: \(datesCount)"
        case let .edit(session):
            guard
                let id = selectedPeriodID,
                let period = session.periods.first(where: { $0.id == id })
            else {
                return "Дней: —"
            }
            return "Дней в периоде: \(period.dates.count)"
        }
    }

    private func configureInitialValues() {
        switch mode {
        case .create:
            title = ""
            emoji = ""
            selectedEmoji = nil
            selectedColor = TPPeriodPalette.default.color
            selectedPeriodID = nil
        case let .edit(session):
            let first = session.periods.first
            selectedPeriodID = first?.id
            if let first {
                apply(first)
            }
        }
    }

    private func selectPeriod(_ period: TPPeriod) {
        selectedPeriodID = period.id
        apply(period)
    }

    private func apply(_ period: TPPeriod) {
        title = period.title ?? ""
        emoji = period.emoji ?? ""
        selectedColor = TPPeriodPalette.closest(to: period.color)
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = trimmedTitle.isEmpty ? nil : trimmedTitle
        let normalizedEmoji = trimmedEmoji.isEmpty ? nil : trimmedEmoji

        switch mode {
        case .create:
            onCreate(normalizedTitle, normalizedEmoji, selectedColor)
        case .edit:
            guard let selectedPeriodID else { return }
            onUpdate(selectedPeriodID, normalizedTitle, normalizedEmoji, selectedColor)
        }
    }

    private func periodDisplayName(_ period: TPPeriod) -> String {
        var parts: [String] = []
        if let emoji = period.emoji, !emoji.isEmpty {
            parts.append(emoji)
        }
        if let title = period.title, !title.isEmpty {
            parts.append(title)
        }
        if parts.isEmpty {
            return "Без названия · \(period.dates.count) дн."
        }
        return parts.joined(separator: " ")
    }
}
