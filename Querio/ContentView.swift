import SwiftUI
import SwiftData

// MARK: - ContentView (Garden Home)

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]

    @State private var selectedBook: Book?
    @State private var showAddBook = false
    @State private var searchText = ""
    @State private var selectedFilter: BookStatus? = nil
    @State private var showRestoreAlert = false
    @State private var restoreCount = 0
    @State private var showMoodboard = false

    private let gridColumns = [GridItem(.adaptive(minimum: 148, maximum: 190), spacing: 12)]

    var filteredBooks: [Book] {
        let filtered = selectedFilter == nil ? books : books.filter { $0.status == selectedFilter }
        if searchText.isEmpty { return filtered }
        return filtered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                gardenHeader
                Divider()
                filterBar
                Divider()
                searchBar
                Divider()
                gardenContent
            }
            .background(Color.gardenWindow)
            .navigationSplitViewColumnWidth(min: 460, ideal: 560)
        } detail: {
            ZStack {
                Color.gardenWindow.ignoresSafeArea()
                if let book = selectedBook {
                    BookDetailView(book: book)
                } else {
                    GardenEmptyDetail()
                }
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView { newBook in
                modelContext.insert(newBook)
                selectedBook = newBook
            }
        }
        .sheet(isPresented: $showMoodboard) {
            MoodboardView()
        }
        .onAppear {
            if books.isEmpty {
                let count = BackupManager.shared.backupBookCount()
                if count > 0 {
                    restoreCount = count
                    showRestoreAlert = true
                }
            } else {
                BackupManager.shared.save(books: books)
            }
        }
        .onChange(of: books) { _, newBooks in
            if !newBooks.isEmpty {
                BackupManager.shared.save(books: newBooks)
            }
        }
        .alert("백업 데이터 복구", isPresented: $showRestoreAlert) {
            Button("복구하기") {
                BackupManager.shared.restore(into: modelContext)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("저장된 백업에서 \(restoreCount)권의 책을 복구할 수 있습니다. 복구하시겠어요?")
        }
    }

    // MARK: - Header

    private var gardenHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Querio")
                    .font(.system(size: 21, weight: .bold))
                Text("Read Less, Absorb More")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !books.isEmpty {
                HStack(spacing: 16) {
                    GardenStatBadge(
                        count: books.filter { $0.status == .finished }.count,
                        emoji: "🌳", label: "완독"
                    )
                    GardenStatBadge(
                        count: books.filter { $0.status == .reading }.count,
                        emoji: "🌿", label: "읽는중"
                    )
                }
                .padding(.trailing, 8)
            }

            // 무드보드
            Button(action: { showMoodboard = true }) {
                Image(systemName: "swatchpalette")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("정원 무드보드")
            .padding(.trailing, 6)

            Button(action: { showAddBook = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("씨앗 심기")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(GardenColors.canopy)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help("새 책 추가")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "전체 \(books.count)그루", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(BookStatus.allCases, id: \.self) { status in
                    let count = books.filter { $0.status == status }.count
                    FilterChip(
                        label: "\(status.gardenEmoji) \(status.rawValue) \(count)",
                        isSelected: selectedFilter == status
                    ) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            TextField("제목, 저자 검색", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.gardenSurface)
        .cornerRadius(8)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Garden Grid

    @ViewBuilder
    private var gardenContent: some View {
        if filteredBooks.isEmpty {
            GardenEmptyState(isFiltered: selectedFilter != nil || !searchText.isEmpty)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(filteredBooks) { book in
                        GardenBookCard(book: book, isSelected: selectedBook?.id == book.id)
                            .onTapGesture { selectedBook = book }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - GardenStatBadge

struct GardenStatBadge: View {
    let count: Int
    let emoji: String
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 3) {
                Text(emoji).font(.system(size: 12))
                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - GardenBookCard

struct GardenBookCard: View {
    let book: Book
    let isSelected: Bool

    private var evidenceCount: Int { book.session?.evidences.count ?? 0 }
    private var roundCount: Int { book.session?.rounds.count ?? 0 }

    private var plantBgColor: Color { GardenColors.background(for: book.status) }

    private var statusColor: Color {
        switch book.status {
        case .wantToRead: return .gray
        case .reading:    return .blue
        case .finished:   return .green
        case .abandoned:  return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Plant area
            ZStack {
                plantBgColor
                PlantIllustration(
                    status: book.status,
                    evidenceCount: evidenceCount,
                    roundCount: roundCount
                )
            }
            .frame(height: 130)

            // Info area
            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(book.author)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Divider().padding(.vertical, 1)

                HStack(spacing: 0) {
                    if evidenceCount > 0 {
                        Label("\(evidenceCount)", systemImage: "leaf.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.2))
                            .padding(.trailing, 8)
                    }
                    if roundCount > 0 {
                        Label("\(roundCount)", systemImage: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(book.status.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.12))
                        .foregroundColor(statusColor)
                        .cornerRadius(5)
                }
            }
            .padding(.horizontal, 11)
            .padding(.top, 9)
            .padding(.bottom, 11)
            .frame(maxWidth: .infinity)
            .background(Color.gardenSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.accentColor : GardenColors.leaf.opacity(0.18),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 6 : 3, x: 0, y: 2)
    }
}

// MARK: - PlantIllustration

struct PlantIllustration: View {
    let status: BookStatus
    let evidenceCount: Int
    let roundCount: Int

    // 줄기 높이
    private var stemHeight: CGFloat {
        switch status {
        case .wantToRead: return 20
        case .reading:    return CGFloat(24 + min(roundCount, 4) * 11)
        case .finished:   return 38
        case .abandoned:  return 24
        }
    }

    // 잎 개수
    private var leafCount: Int {
        switch status {
        case .wantToRead: return 1
        case .reading:    return min(2 + evidenceCount, 8)
        case .finished:   return 0
        case .abandoned:  return max(1, min(evidenceCount / 2 + 1, 5))
        }
    }

    // 수관(캐노피) 반지름 — finished only
    private var canopyRadius: CGFloat {
        CGFloat(32 + min(evidenceCount, 10) * 2)
    }

    private var stemColor: Color {
        switch status {
        case .reading:  return Color(red: 0.22, green: 0.55, blue: 0.18)
        case .finished: return Color(red: 0.42, green: 0.26, blue: 0.08)
        default:        return Color(red: 0.5, green: 0.4, blue: 0.28)
        }
    }

    private var leafColor: Color {
        switch status {
        case .wantToRead: return Color(red: 0.35, green: 0.68, blue: 0.28).opacity(0.85)
        case .reading:    return Color(red: 0.20, green: 0.62, blue: 0.18)
        case .finished:   return Color(red: 0.12, green: 0.55, blue: 0.12)
        case .abandoned:  return Color(red: 0.52, green: 0.40, blue: 0.22).opacity(0.75)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 화분 위의 식물
            Group {
                if status == .finished {
                    treeView.offset(y: -(potHeight + soilHeight))
                } else {
                    seedlingView.offset(y: -(potHeight + soilHeight))
                }
            }

            // 흙 선
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.32, green: 0.20, blue: 0.08))
                .frame(width: 66, height: soilHeight)
                .offset(y: -potHeight)

            // 화분
            potView
        }
        .frame(width: 90, height: 120)
    }

    private let potHeight: CGFloat = 32
    private let soilHeight: CGFloat = 5

    // MARK: 화분

    private var potView: some View {
        ZStack(alignment: .top) {
            // 몸체
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.70, green: 0.42, blue: 0.22))
                .frame(width: 52, height: 30)
                .offset(y: 4)
            // 테두리
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.56, green: 0.32, blue: 0.16))
                .frame(width: 62, height: 8)
        }
        .frame(width: 62, height: 34)
    }

    // MARK: 완독 나무 (줄기 + 수관)

    private var treeView: some View {
        VStack(spacing: 0) {
            // 수관
            ZStack {
                Ellipse()
                    .fill(leafColor)
                    .frame(width: canopyRadius * 1.15, height: canopyRadius)

                // 수관 내 음영 레이어 (입체감)
                Ellipse()
                    .fill(leafColor.opacity(0.45))
                    .frame(width: canopyRadius * 0.55, height: canopyRadius * 0.55)
                    .offset(x: -6, y: 6)

                // 증거 열매 (최대 5개)
                ForEach(Array(fruitOffsets.prefix(min(evidenceCount / 2, 5)).enumerated()), id: \.offset) { idx, pos in
                    Circle()
                        .fill(Color.orange.opacity(0.9))
                        .frame(width: 7, height: 7)
                        .offset(
                            x: pos.x * canopyRadius / 50,
                            y: pos.y * canopyRadius / 50
                        )
                }
            }

            // 줄기(trunk)
            Rectangle()
                .fill(stemColor)
                .frame(width: 8, height: stemHeight)
        }
    }

    // MARK: 새싹 / 자라는 식물

    private var seedlingView: some View {
        ZStack(alignment: .bottom) {
            // 줄기
            Rectangle()
                .fill(stemColor)
                .frame(width: status == .wantToRead ? 2 : 3, height: stemHeight)

            // 잎들
            ForEach(0..<leafCount, id: \.self) { i in
                let isLeft = i % 2 == 0
                let ratio = CGFloat(i + 1) / CGFloat(max(leafCount, 1))
                let yOff = stemHeight * ratio - stemHeight * 0.5
                let leafW = CGFloat(status == .wantToRead ? 13 : 11 + min(i, 4) * 3)
                let leafH = leafW * 0.52
                let angle: Double = status == .abandoned ? 40 : -26

                Ellipse()
                    .fill(leafColor)
                    .frame(width: leafW, height: leafH)
                    .rotationEffect(.degrees(isLeft ? angle : -angle))
                    .offset(
                        x: isLeft ? -(leafW * 0.52) : (leafW * 0.52),
                        y: -yOff
                    )
            }
        }
        .frame(height: stemHeight)
    }

    // 고정 열매 위치 (결정론적)
    private let fruitOffsets: [(x: CGFloat, y: CGFloat)] = [
        (-18, -8), (16, -14), (-12, 9), (20, 5), (-6, -22)
    ]
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? GardenColors.canopy : Color.gardenSurface)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty States

struct GardenEmptyState: View {
    let isFiltered: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text("🪴")
                .font(.system(size: 60))
            Text(isFiltered ? "조건에 맞는 책이 없어요" : "첫 번째 씨앗을 심어보세요")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            if !isFiltered {
                Text("읽고 싶은 책을 추가하면\n여기에 식물로 자라납니다")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GardenEmptyDetail: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🌱")
                .font(.system(size: 64))
            Text("책을 선택하세요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Text("왼쪽 정원에서 식물을 클릭하면\n독서 기록을 볼 수 있어요")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gardenWindow)
    }
}
