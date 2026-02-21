import SwiftUI
import SwiftData
import AppKit

@main
struct QuerioApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Book.self, ReadingSession.self])

        // CloudKit iCloud 동기화 시도, 실패(미로그인·미설정) 시 로컬 저장소로 폴백
        let cloudConfig = ModelConfiguration(
            "Querio",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.querio.app")
        )

        if let cloudContainer = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            container = cloudContainer
        } else {
            // iCloud 미사용 환경에서도 로컬 영속성 보장
            print("⚠️ CloudKit 초기화 실패 — 로컬 저장소로 동작")
            let localConfig = ModelConfiguration("Querio", schema: schema, isStoredInMemoryOnly: false)
            guard let localContainer = try? ModelContainer(for: schema, configurations: [localConfig]) else {
                fatalError("ModelContainer 생성 실패")
            }
            container = localContainer
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .frame(minWidth: 1100, minHeight: 700)
                .background(GardenWindowTint())  // 타이틀바 초록 적용
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
    }
}

// MARK: - 타이틀바 초록 틴트
// NSWindow에 직접 접근해 titlebarAppearsTransparent + backgroundColor 적용

struct GardenWindowTint: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(name: "gardenWindowBg") { appearance in
                appearance.bestMatch(from: [.darkAqua]) == .darkAqua
                    ? NSColor(red: 0.11, green: 0.17, blue: 0.11, alpha: 1)
                    : NSColor(red: 0.93, green: 0.96, blue: 0.92, alpha: 1)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
