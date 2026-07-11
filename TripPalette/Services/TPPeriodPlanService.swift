import Foundation
import SwiftData

@MainActor
final class TPPeriodPlanService: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        consolidateSharedDays()
    }

    /// План дня общий для всех промежутков: ключ — календарная дата.
    func blocks(day: DateComponents) -> [TPPlanBlock] {
        let records = fetchRecords(day: day)
        guard !records.isEmpty else { return [] }

        let ranked = records.map { record -> (TPPeriodPlanDayRecord, [TPPlanBlock]) in
            (record, Self.decodeBlocks(record.blocksData))
        }
        return ranked
            .max { lhs, rhs in lhs.1.count < rhs.1.count }
            .map(\.1) ?? []
    }

    func save(day: DateComponents, blocks: [TPPlanBlock]) {
        let year = day.year ?? 0
        let month = day.month ?? 0
        let dayValue = day.day ?? 0
        let records = fetchRecords(day: day)

        if blocks.isEmpty {
            for record in records {
                modelContext.delete(record)
            }
        } else {
            let data = Self.encodeBlocks(blocks)
            if let primary = records.first {
                primary.blocksData = data
                for duplicate in records.dropFirst() {
                    modelContext.delete(duplicate)
                }
            } else {
                modelContext.insert(
                    TPPeriodPlanDayRecord(
                        periodID: Self.sharedPeriodID,
                        year: year,
                        month: month,
                        day: dayValue,
                        blocksData: data
                    )
                )
            }
        }

        try? modelContext.save()
    }

    /// Удаляет планы дней, которые больше не входят ни в один оставшийся промежуток.
    func deleteExclusiveDays(
        of period: TPPeriod,
        retainedPeriods: [TPPeriod]
    ) {
        for components in period.dates {
            let day = DateComponents(
                year: components.year,
                month: components.month,
                day: components.day
            )
            let usedElsewhere = retainedPeriods.contains { retained in
                retained.dates.contains { TPCalendarDate.isSameDay($0, day) }
            }
            guard !usedElsewhere else { continue }

            for record in fetchRecords(day: day) {
                modelContext.delete(record)
            }
        }

        try? modelContext.save()
    }

    /// Склеивает старые записи одного дня из разных periodID в одну.
    private func consolidateSharedDays() {
        let descriptor = FetchDescriptor<TPPeriodPlanDayRecord>()
        let records = (try? modelContext.fetch(descriptor)) ?? []
        guard !records.isEmpty else { return }

        let grouped = Dictionary(grouping: records) { record in
            "\(record.year)-\(record.month)-\(record.day)"
        }

        var didChange = false
        for (_, group) in grouped where group.count > 1 {
            let ranked = group.map { record -> (TPPeriodPlanDayRecord, Int) in
                (record, Self.decodeBlocks(record.blocksData).count)
            }
            guard let primary = ranked.max(by: { $0.1 < $1.1 })?.0 else { continue }
            primary.periodID = Self.sharedPeriodID
            for duplicate in group where duplicate.id != primary.id {
                modelContext.delete(duplicate)
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }

    private func fetchRecords(day: DateComponents) -> [TPPeriodPlanDayRecord] {
        let year = day.year ?? 0
        let month = day.month ?? 0
        let dayValue = day.day ?? 0

        let descriptor = FetchDescriptor<TPPeriodPlanDayRecord>(
            predicate: #Predicate {
                $0.year == year
                    && $0.month == month
                    && $0.day == dayValue
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Маркер «день общий», не привязан к конкретному промежутку.
    private static let sharedPeriodID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static func encodeBlocks(_ blocks: [TPPlanBlock]) -> Data {
        (try? JSONEncoder().encode(blocks)) ?? Data()
    }

    private static func decodeBlocks(_ data: Data) -> [TPPlanBlock] {
        (try? JSONDecoder().decode([TPPlanBlock].self, from: data)) ?? []
    }
}
