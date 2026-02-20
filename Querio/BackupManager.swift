import Foundation
import SwiftData

// MARK: - Backup DTOs

struct BookBackup: Codable {
    let exportedAt: Date
    let version: Int
    let books: [BookDTO]
}

struct BookDTO: Codable {
    let id: UUID
    let title: String
    let author: String
    let coverImageURL: String?
    let isbn: String?
    let totalPages: Int?
    let createdAt: Date
    let status: String
    let phenomenon: String
    let goal: String
    let abductiveQuestions: [String]
    let hypotheses: [String]
    let revisedExplanation: String?
    let oneAction: String?
    let finishedAt: Date?
    let session: SessionDTO?
}

struct SessionDTO: Codable {
    let currentPage: Int
    let evidences: [EvidenceDTO]
    let rounds: [RoundDTO]
    let notes: String
}

struct EvidenceDTO: Codable {
    let id: UUID
    let quote: String
    let page: Int?
    let type: String
    let memo: String
    let createdAt: Date
}

struct RoundDTO: Codable {
    let id: UUID
    let chapter: String
    let guess: String
    let goalAchieved: Bool
    let createdAt: Date
}

// MARK: - BackupManager

class BackupManager {
    static let shared = BackupManager()
    private init() { setupDirectory() }

    private var backupDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Querio")
    }

    private var backupURL: URL {
        backupDirectory.appendingPathComponent("books_backup.json")
    }

    private func setupDirectory() {
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }

    var hasBackup: Bool {
        FileManager.default.fileExists(atPath: backupURL.path)
    }

    func backupBookCount() -> Int {
        loadBackup()?.books.count ?? 0
    }

    // MARK: - Save

    func save(books: [Book]) {
        let dtos = books.map { book in
            BookDTO(
                id: book.id,
                title: book.title,
                author: book.author,
                coverImageURL: book.coverImageURL,
                isbn: book.isbn,
                totalPages: book.totalPages,
                createdAt: book.createdAt,
                status: book.status.rawValue,
                phenomenon: book.phenomenon,
                goal: book.goal,
                abductiveQuestions: book.abductiveQuestions,
                hypotheses: book.hypotheses,
                revisedExplanation: book.revisedExplanation,
                oneAction: book.oneAction,
                finishedAt: book.finishedAt,
                session: book.session.map { s in
                    SessionDTO(
                        currentPage: s.currentPage,
                        evidences: s.evidences.map { e in
                            EvidenceDTO(id: e.id, quote: e.quote, page: e.page,
                                        type: e.type.rawValue, memo: e.memo, createdAt: e.createdAt)
                        },
                        rounds: s.rounds.map { r in
                            RoundDTO(id: r.id, chapter: r.chapter, guess: r.guess,
                                     goalAchieved: r.goalAchieved, createdAt: r.createdAt)
                        },
                        notes: s.notes
                    )
                }
            )
        }

        let backup = BookBackup(exportedAt: Date(), version: 1, books: dtos)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(backup) else { return }
        try? data.write(to: backupURL, options: .atomic)
    }

    // MARK: - Load

    private func loadBackup() -> BookBackup? {
        guard let data = try? Data(contentsOf: backupURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BookBackup.self, from: data)
    }

    // MARK: - Restore

    @discardableResult
    func restore(into context: ModelContext) -> Int {
        guard let backup = loadBackup() else { return 0 }
        var count = 0

        for dto in backup.books {
            let book = Book(
                title: dto.title,
                author: dto.author,
                coverImageURL: dto.coverImageURL,
                isbn: dto.isbn,
                totalPages: dto.totalPages,
                phenomenon: dto.phenomenon,
                goal: dto.goal,
                abductiveQuestions: dto.abductiveQuestions,
                hypotheses: dto.hypotheses
            )
            book.id = dto.id
            book.createdAt = dto.createdAt
            book.status = BookStatus(rawValue: dto.status) ?? .wantToRead
            book.revisedExplanation = dto.revisedExplanation
            book.oneAction = dto.oneAction
            book.finishedAt = dto.finishedAt

            if let sDTO = dto.session {
                let session = ReadingSession()
                session.currentPage = sDTO.currentPage
                session.notes = sDTO.notes
                session.evidences = sDTO.evidences.map { e in
                    Evidence(
                        id: e.id, quote: e.quote, page: e.page,
                        type: EvidenceType(rawValue: e.type) ?? .newDiscovery,
                        memo: e.memo, createdAt: e.createdAt
                    )
                }
                session.rounds = sDTO.rounds.map { r in
                    ReadingRound(id: r.id, chapter: r.chapter, guess: r.guess,
                                 goalAchieved: r.goalAchieved, createdAt: r.createdAt)
                }
                book.session = session
            }

            context.insert(book)
            count += 1
        }

        return count
    }
}
