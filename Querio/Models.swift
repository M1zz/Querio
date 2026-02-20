import SwiftData
import Foundation

// MARK: - Book Model
@Model
class Book {
    var id: UUID
    var title: String
    var author: String
    var coverImageURL: String?
    var isbn: String?
    var totalPages: Int?
    var createdAt: Date
    var status: BookStatus

    // POR 독서 전 설계
    var phenomenon: String              // 내 삶의 현상
    var goal: String                    // 목표: 어떤 상태가 되고 싶은지
    var abductiveQuestions: [String]    // 귀추적 질문들 (여러 개)
    var hypotheses: [String]            // 나의 가설들 (여러 개)

    // 독서 후 결론
    var revisedExplanation: String?
    var oneAction: String?
    var finishedAt: Date?

    @Relationship(deleteRule: .cascade) var session: ReadingSession?

    init(
        title: String,
        author: String,
        coverImageURL: String? = nil,
        isbn: String? = nil,
        totalPages: Int? = nil,
        phenomenon: String = "",
        goal: String = "",
        abductiveQuestions: [String] = [],
        hypotheses: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.coverImageURL = coverImageURL
        self.isbn = isbn
        self.totalPages = totalPages
        self.createdAt = Date()
        self.status = .wantToRead
        self.phenomenon = phenomenon
        self.goal = goal
        self.abductiveQuestions = abductiveQuestions
        self.hypotheses = hypotheses
    }
}

enum BookStatus: String, Codable, CaseIterable {
    case wantToRead = "읽고 싶음"
    case reading = "읽는 중"
    case finished = "완독"
    case abandoned = "포기"

    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading: return "book.open"
        case .finished: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .wantToRead: return "gray"
        case .reading: return "blue"
        case .finished: return "green"
        case .abandoned: return "red"
        }
    }
}

// MARK: - Reading Session Model
@Model
class ReadingSession {
    var id: UUID
    var currentPage: Int
    var evidences: [Evidence]
    var rounds: [ReadingRound]
    var notes: String
    var updatedAt: Date

    init() {
        self.id = UUID()
        self.currentPage = 0
        self.evidences = []
        self.rounds = []
        self.notes = ""
        self.updatedAt = Date()
    }
}

// MARK: - Reading Round (POR: 장 선택 → 추측 → 독서)
struct ReadingRound: Codable, Identifiable {
    var id: UUID = UUID()
    var chapter: String         // 선택한 장
    var guess: String           // 이 장에서 기대하는 것
    var goalAchieved: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Evidence (증거)
struct Evidence: Codable, Identifiable {
    var id: UUID = UUID()
    var quote: String
    var page: Int?
    var type: EvidenceType
    var memo: String
    var createdAt: Date = Date()
}

enum EvidenceType: String, Codable, CaseIterable {
    case supports = "가설 지지"
    case refutes = "가설 반박"
    case newDiscovery = "새로운 발견"

    var icon: String {
        switch self {
        case .supports: return "checkmark.circle.fill"
        case .refutes: return "xmark.circle.fill"
        case .newDiscovery: return "lightbulb.fill"
        }
    }

    var colorName: String {
        switch self {
        case .supports: return "green"
        case .refutes: return "red"
        case .newDiscovery: return "orange"
        }
    }
}

// MARK: - Kakao Book Search Result
struct KakaoBookSearchResult: Codable {
    let documents: [KakaoBook]
    let meta: KakaoMeta
}

struct KakaoBook: Codable, Identifiable {
    var id: String { isbn }
    let title: String
    let authors: [String]
    let isbn: String
    let thumbnail: String
    let contents: String
    let url: String
    let publisher: String

    var authorString: String { authors.joined(separator: ", ") }
}

struct KakaoMeta: Codable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}
