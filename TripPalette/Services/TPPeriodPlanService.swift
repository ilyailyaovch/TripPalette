import Foundation
import SwiftData

@MainActor
final class TPPeriodPlanService: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func blocks(periodID: UUID, day: DateComponents) -> [TPPlanBlock] {
        guard let record = fetchRecord(periodID: periodID, day: day) else {
            return []
        }
        return Self.decodeBlocks(record.blocksData)
    }

    func save(periodID: UUID, day: DateComponents, blocks: [TPPlanBlock]) {
        let year = day.year ?? 0
        let month = day.month ?? 0
        let dayValue = day.day ?? 0

        if let record = fetchRecord(periodID: periodID, day: day) {
            if blocks.isEmpty {
                modelContext.delete(record)
            } else {
                record.blocksData = Self.encodeBlocks(blocks)
            }
        } else if !blocks.isEmpty {
            modelContext.insert(
                TPPeriodPlanDayRecord(
                    periodID: periodID,
                    year: year,
                    month: month,
                    day: dayValue,
                    blocksData: Self.encodeBlocks(blocks)
                )
            )
        }

        try? modelContext.save()
    }

    func deleteAll(for periodID: UUID) {
        let targetID = periodID
        let descriptor = FetchDescriptor<TPPeriodPlanDayRecord>(
            predicate: #Predicate { $0.periodID == targetID }
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }

    private func fetchRecord(periodID: UUID, day: DateComponents) -> TPPeriodPlanDayRecord? {
        let targetID = periodID
        let year = day.year ?? 0
        let month = day.month ?? 0
        let dayValue = day.day ?? 0

        var descriptor = FetchDescriptor<TPPeriodPlanDayRecord>(
            predicate: #Predicate {
                $0.periodID == targetID
                    && $0.year == year
                    && $0.month == month
                    && $0.day == dayValue
            }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private static func encodeBlocks(_ blocks: [TPPlanBlock]) -> Data {
        (try? JSONEncoder().encode(blocks)) ?? Data()
    }

    private static func decodeBlocks(_ data: Data) -> [TPPlanBlock] {
        (try? JSONDecoder().decode([TPPlanBlock].self, from: data)) ?? []
    }
}
