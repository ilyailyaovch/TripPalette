import SwiftUI

struct TPCalendarView: View {
    @StateObject private var viewModel: TPCalendarViewModel

    init(viewModel: TPCalendarViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state.displayMode {
                case .month:
                    monthScroll
                case .year:
                    TPYearGridView(viewModel: viewModel)
                }
            }
            .background(Color.tp_backgroundPrimary)
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleDisplayMode()
                    } label: {
                        Label(
                            viewModel.state.displayModeToggleTitle,
                            systemImage: viewModel.state.displayModeToggleSystemImage
                        )
                    }
                    .accessibilityLabel(viewModel.state.displayModeToggleTitle)
                }
            }
            .sheet(isPresented: sheetPresented) {
                periodSheetContent
                    .id(sheetIdentity)
            }
        }
    }

    private var sheetIdentity: String {
        if let draft = viewModel.state.periodDraft {
            return "create-\(draft.id)"
        }
        if let session = viewModel.state.editSession {
            let periodIDs = session.periods.map(\.id.uuidString).joined(separator: ",")
            return "edit-\(session.id)-\(periodIDs)"
        }
        return "none"
    }

    @ViewBuilder
    private var periodSheetContent: some View {
        if let draft = viewModel.state.periodDraft {
            TPPeriodEditorView(
                mode: .create(datesCount: draft.dates.count),
                onCreate: viewModel.savePeriod,
                onUpdate: viewModel.updatePeriod,
                onDelete: viewModel.deletePeriod,
                onCancel: viewModel.cancelPeriodEditing
            )
        } else if let session = viewModel.state.editSession {
            TPPeriodEditorView(
                mode: .edit(session),
                onCreate: viewModel.savePeriod,
                onUpdate: viewModel.updatePeriod,
                onDelete: viewModel.deletePeriod,
                onCancel: viewModel.cancelPeriodEditing
            )
        }
    }

    private var sheetPresented: Binding<Bool> {
        Binding(
            get: {
                viewModel.state.periodDraft != nil || viewModel.state.editSession != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelPeriodEditing()
                }
            }
        )
    }

    private var monthScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.state.availableMonths, id: \.self) { month in
                        TPMonthSectionView(month: month, viewModel: viewModel)
                            .id(monthID(month))
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.bottom, 24)
            }
            .task(id: monthID(viewModel.state.focusedMonth)) {
                await scrollToFocusedMonth(proxy: proxy)
            }
            .onChange(of: viewModel.state.focusedMonth) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(monthID(newValue), anchor: .top)
                }
            }
        }
    }

    @MainActor
    private func scrollToFocusedMonth(proxy: ScrollViewProxy) async {
        await Task.yield()
        proxy.scrollTo(monthID(viewModel.state.focusedMonth), anchor: .top)
    }

    private func monthID(_ month: DateComponents) -> String {
        "\(month.year ?? 0)-\(month.month ?? 0)"
    }
}
