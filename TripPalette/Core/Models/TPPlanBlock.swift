import Foundation

enum TPPlanBlockKind: String, Codable, CaseIterable, Equatable {
    case text
    case bullet
    case todo
    case toggle
    case link
}

struct TPPlanBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var kind: TPPlanBlockKind
    var text: String
    var isDone: Bool
    var isExpanded: Bool
    var detail: String
    var url: String

    init(
        id: UUID = UUID(),
        kind: TPPlanBlockKind,
        text: String = "",
        isDone: Bool = false,
        isExpanded: Bool = true,
        detail: String = "",
        url: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.isDone = isDone
        self.isExpanded = isExpanded
        self.detail = detail
        self.url = url
    }

    static func make(_ kind: TPPlanBlockKind) -> TPPlanBlock {
        TPPlanBlock(kind: kind)
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, text, isDone, isExpanded, detail, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(TPPlanBlockKind.self, forKey: .kind)
        text = try container.decode(String.self, forKey: .text)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? true
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

struct TPDayPlan: Identifiable, Equatable {
    var day: DateComponents
    var blocks: [TPPlanBlock]

    var id: String {
        "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }
}
