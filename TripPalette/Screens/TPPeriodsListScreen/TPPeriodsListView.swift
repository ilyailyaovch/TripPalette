import SwiftUI

struct TPPeriodsListView: View {
    @ObservedObject var viewModel: TPPeriodsListViewModel
    let planService: TPPeriodPlanService
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.periods.isEmpty {
                    emptyState
                } else {
                    periodsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.tp_backgroundPrimary)
            .navigationTitle("Планы")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Настройки")
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                TPPeriodsListSettingsView(viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(emptyTitle)
                .font(.body)
                .foregroundStyle(Color.tp_textPrimary)
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.tp_textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var emptyTitle: String {
        if viewModel.state.showOnlyUpcoming, !viewModel.state.sourcePeriods.isEmpty {
            return "Нет актуальных планов"
        }
        return "Пока нет планов"
    }

    private var emptySubtitle: String {
        if viewModel.state.showOnlyUpcoming, !viewModel.state.sourcePeriods.isEmpty {
            return "Выключите фильтр в настройках, чтобы увидеть прошедшие промежутки"
        }
        return "Добавь период в календаре — он появится здесь"
    }

    private var periodsList: some View {
        List {
            ForEach(viewModel.state.periods) { period in
                NavigationLink {
                    TPPeriodPlanFactory.configure(
                        period: period,
                        planService: planService
                    )
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(period.color)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(periodTitle(period))
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.tp_textPrimary)

                            Text(dateRangeText(period))
                                .font(.subheadline)
                                .foregroundStyle(Color.tp_textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .listRowBackground(Color.tp_backgroundSecondary)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deletePeriod(id: period.id)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func periodTitle(_ period: TPPeriod) -> String {
        let emoji = period.emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = period.title?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (emoji?.isEmpty == false, title?.isEmpty == false) {
        case (true, true):
            return "\(emoji!) \(title!)"
        case (true, false):
            return emoji!
        case (false, true):
            return title!
        case (false, false):
            return "Без названия"
        }
    }

    private func dateRangeText(_ period: TPPeriod) -> String {
        let dates = period.dates
            .compactMap(TPCalendarDate.date(from:))
            .sorted()

        guard let first = dates.first, let last = dates.last else {
            return "Без дат"
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("dMMMMy")

        if Calendar.current.isDate(first, inSameDayAs: last) {
            return formatter.string(from: first)
        }

        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
}

private struct TPPeriodsListSettingsView: View {
    @ObservedObject var viewModel: TPPeriodsListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TPPeriodsListSortOrder.allCases) { order in
                        Button {
                            viewModel.setSortOrder(order)
                        } label: {
                            HStack {
                                Text(order.title)
                                    .foregroundStyle(Color.tp_textPrimary)
                                Spacer()
                                if viewModel.state.sortOrder == order {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.tp_tint)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Сортировка")
                }

                Section {
                    Toggle(
                        "Только актуальные",
                        isOn: Binding(
                            get: { viewModel.state.showOnlyUpcoming },
                            set: { viewModel.setShowOnlyUpcoming($0) }
                        )
                    )
                    .tint(Color.tp_tint)
                } footer: {
                    Text("Показывать промежутки, которые ещё не закончились")
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
