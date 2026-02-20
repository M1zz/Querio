import SwiftUI
import SwiftData

@main
struct QuerioApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Book.self, ReadingSession.self])
        // 스토어 이름 "Querio"로 고정 — 번들 ID가 바뀌어도 데이터 유지
        let config = ModelConfiguration("Querio", schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
    }
}
