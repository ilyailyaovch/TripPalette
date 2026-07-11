import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class TPPeriodService: ObservableObject {
    @Published private(set) var periods: [TPPeriod] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<TPPeriodRecord>(
            sortBy: [SortDescriptor(\.id)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        periods = records
            .compactMap(Self.period(from:))
            .sorted { lhs, rhs in
                Self.startDate(of: lhs) < Self.startDate(of: rhs)
            }
    }

    func add(_ period: TPPeriod) {
        modelContext.insert(Self.record(from: period))
        saveAndReload()
    }

    func update(_ period: TPPeriod) {
        let targetID = period.id
        var descriptor = FetchDescriptor<TPPeriodRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.title = period.title
        record.emoji = period.emoji
        record.colorHex = period.color.tp_hexString
        record.datesData = Self.encodeDates(period.dates)
        saveAndReload()
    }

    func delete(id: UUID) {
        let targetID = id
        var descriptor = FetchDescriptor<TPPeriodRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        guard let record = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(record)
        saveAndReload()
    }

    private func saveAndReload() {
        try? modelContext.save()
        reload()
    }

    private static func record(from period: TPPeriod) -> TPPeriodRecord {
        TPPeriodRecord(
            id: period.id,
            title: period.title,
            emoji: period.emoji,
            colorHex: period.color.tp_hexString,
            datesData: encodeDates(period.dates)
        )
    }

    private static func period(from record: TPPeriodRecord) -> TPPeriod? {
        guard let dates = decodeDates(record.datesData) else { return nil }
        return TPPeriod(
            id: record.id,
            title: record.title,
            emoji: record.emoji,
            color: Color(tp_hex: record.colorHex),
            dates: dates
        )
    }

    private static func encodeDates(_ dates: Set<DateComponents>) -> Data {
        let payload = dates.map {
            TPCodableDay(year: $0.year ?? 0, month: $0.month ?? 0, day: $0.day ?? 0)
        }
        return (try? JSONEncoder().encode(payload)) ?? Data()
    }

    private static func decodeDates(_ data: Data) -> Set<DateComponents>? {
        guard let payload = try? JSONDecoder().decode([TPCodableDay].self, from: data) else {
            return nil
        }
        return Set(
            payload.map {
                DateComponents(year: $0.year, month: $0.month, day: $0.day)
            }
        )
    }

    private static func startDate(of period: TPPeriod) -> Date {
        period.dates
            .compactMap(TPCalendarDate.date(from:))
            .min() ?? .distantFuture
    }
}

private struct TPCodableDay: Codable {
    var year: Int
    var month: Int
    var day: Int
}
