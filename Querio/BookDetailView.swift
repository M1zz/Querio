import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0
    @State private var showDeleteAlert = false

    var tabs: [(String, String)] {
        [("설계", "lightbulb"), ("독서 중", "book.open"), ("결론", "checkmark.seal")]
    }

    var body: some View {
        VStack(spacing: 0) {
            bookHeader
            Divider()

            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                    Button(action: { selectedTab = i }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.1).font(.system(size: 12))
                            Text(tab.0).font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(selectedTab == i ? .accentColor : .secondary)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(
                            Rectangle().fill(Color.clear)
                                .overlay(alignment: .bottom) {
                                    if selectedTab == i {
                                        Rectangle().fill(Color.accentColor).frame(height: 2)
                                    }
                                }
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()

                Menu {
                    ForEach(BookStatus.allCases, id: \.self) { status in
                        Button(action: { book.status = status }) {
                            Label(status.rawValue, systemImage: status.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: book.status.icon)
                        Text(book.status.rawValue)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor)).cornerRadius(20)
                }
                .menuStyle(.borderlessButton).padding(.trailing, 16)
            }

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    switch selectedTab {
                    case 0: PreReadingDesignTab(book: book)
                    case 1: ReadingTab(book: book)
                    case 2: ConclusionTab(book: book)
                    default: EmptyView()
                    }
                }
                .padding(28)
            }
        }
        .alert("책을 삭제하시겠어요?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) { modelContext.delete(book) }
            Button("취소", role: .cancel) {}
        }
    }

    var bookHeader: some View {
        HStack(spacing: 16) {
            Group {
                if let urlString = book.coverImageURL, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(Text(String(book.title.prefix(1))).font(.system(size: 22, weight: .bold)).foregroundColor(.accentColor))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Text(String(book.title.prefix(1))).font(.system(size: 22, weight: .bold)).foregroundColor(.accentColor))
                }
            }
            .frame(width: 52, height: 72).cornerRadius(8).clipped()
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.system(size: 18, weight: .bold))
                Text(book.author).font(.system(size: 13)).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Label(book.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                    if let session = book.session {
                        Label("\(session.evidences.count)개 증거", systemImage: "doc.text.magnifyingglass")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                        if !session.rounds.isEmpty {
                            Label("\(session.rounds.count)라운드", systemImage: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 11)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Spacer()
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(.secondary)
            }
            .buttonStyle(.plain).help("삭제")
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
    }
}

// MARK: - Tab 1: Pre-Reading Design
struct PreReadingDesignTab: View {
    @Bindable var book: Book
    @State private var newQuestion = ""
    @State private var newHypothesis = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            SectionHeader(icon: "🔍", title: "현상 포착", subtitle: "이 책을 읽게 된 내 삶의 문제/불편함")
            EditableTextArea(text: $book.phenomenon, placeholder: "요즘 내 삶에서 이상하거나 불편한 것...")

            Divider().opacity(0.5)

            SectionHeader(icon: "🎯", title: "목표", subtitle: "이 책을 활용했을 때 어떤 상태가 되고 싶은지")
            EditableTextArea(text: $book.goal, placeholder: "\"[상황]에서 [행동]할 수 있게 되고 싶다\"")

            Divider().opacity(0.5)

            // 귀추적 질문들
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "❓", title: "귀추적 질문들", subtitle: "현상에서 도출한 탐색 질문들 (\(book.abductiveQuestions.count)개)")

                if book.abductiveQuestions.isEmpty {
                    Text("아직 질문이 없어요. 아래에서 추가해보세요.")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                } else {
                    ForEach(book.abductiveQuestions, id: \.self) { question in
                        HStack(spacing: 10) {
                            let idx = book.abductiveQuestions.firstIndex(of: question) ?? 0
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.accentColor)
                                .frame(width: 20, height: 20)
                                .background(Color.accentColor.opacity(0.1)).clipShape(Circle())
                            Text(question).font(.system(size: 13))
                            Spacer()
                            Button(action: { book.abductiveQuestions.removeAll { $0 == question } }) {
                                Image(systemName: "minus.circle").foregroundColor(.secondary.opacity(0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }
                }

                HStack(spacing: 8) {
                    TextField("새 질문 추가...", text: $newQuestion)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                        .onSubmit { addQuestion() }
                    Button(action: addQuestion) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newQuestion.isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain).disabled(newQuestion.isEmpty)
                }
            }

            Divider().opacity(0.5)

            // 가설들
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "💡", title: "나의 가설들", subtitle: "책을 읽기 전 내가 미리 세운 답들 (\(book.hypotheses.count)개)")

                if book.hypotheses.isEmpty {
                    Text("아직 가설이 없어요. 아래에서 추가해보세요.")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                } else {
                    ForEach(book.hypotheses, id: \.self) { hypothesis in
                        HStack(spacing: 10) {
                            let idx = book.hypotheses.firstIndex(of: hypothesis) ?? 0
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.purple)
                                .frame(width: 20, height: 20)
                                .background(Color.purple.opacity(0.1)).clipShape(Circle())
                            Text(hypothesis).font(.system(size: 13))
                            Spacer()
                            Button(action: { book.hypotheses.removeAll { $0 == hypothesis } }) {
                                Image(systemName: "minus.circle").foregroundColor(.secondary.opacity(0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }
                }

                HStack(spacing: 8) {
                    TextField("새 가설 추가...", text: $newHypothesis)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                        .onSubmit { addHypothesis() }
                    Button(action: addHypothesis) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newHypothesis.isEmpty ? .secondary : .purple)
                    }
                    .buttonStyle(.plain).disabled(newHypothesis.isEmpty)
                }
            }
        }
    }

    func addQuestion() {
        let q = newQuestion.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        book.abductiveQuestions.append(q)
        newQuestion = ""
    }

    func addHypothesis() {
        let h = newHypothesis.trimmingCharacters(in: .whitespaces)
        guard !h.isEmpty else { return }
        book.hypotheses.append(h)
        newHypothesis = ""
    }
}

// MARK: - Tab 2: Reading (POR: 장 단위 독서)
struct ReadingTab: View {
    @Bindable var book: Book
    @State private var showAddEvidence = false
    @State private var showAddRound = false

    var evidences: [Evidence] { book.session?.evidences ?? [] }
    var rounds: [ReadingRound] { book.session?.rounds ?? [] }

    var supportCount: Int { evidences.filter { $0.type == .supports }.count }
    var refuteCount: Int { evidences.filter { $0.type == .refutes }.count }
    var discoveryCount: Int { evidences.filter { $0.type == .newDiscovery }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // 목표 reminder
            if !book.goal.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("달성할 목표")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "scope").foregroundColor(.green).font(.system(size: 15))
                        Text(book.goal).font(.system(size: 13)).foregroundColor(.primary.opacity(0.8))
                        Spacer()
                    }
                    .padding(14).background(Color.green.opacity(0.07)).cornerRadius(10)
                }
            }

            // 가설들 reminder
            if !book.hypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("추적 중인 가설 (\(book.hypotheses.count)개)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    VStack(spacing: 6) {
                        ForEach(book.hypotheses.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(i + 1)")
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.purple)
                                    .frame(width: 18, height: 18)
                                    .background(Color.purple.opacity(0.1)).clipShape(Circle())
                                Text(book.hypotheses[i])
                                    .font(.system(size: 12)).italic().foregroundColor(.primary.opacity(0.8))
                                Spacer()
                            }
                        }
                    }
                    .padding(14).background(Color.purple.opacity(0.07)).cornerRadius(10)
                }
            }

            // POR 읽기 라운드 (장 선택 → 추측 → 독서)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("읽기 라운드")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                        Text("딱 1장만 고른다면? 가장 목표에 가까운 장을 선택하세요")
                            .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                    Button(action: { showAddRound = true }) {
                        Label("라운드 추가", systemImage: "plus")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain).foregroundColor(.accentColor)
                }

                if rounds.isEmpty {
                    Text("읽을 장을 선택하고 기대하는 것을 추측한 뒤 읽기 시작하세요")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(rounds) { round in
                            ReadingRoundCard(round: round)
                        }
                    }
                }
            }

            // 증거 통계 + 추가
            HStack(spacing: 16) {
                EvidenceStat(count: supportCount, label: "지지", color: .green, icon: "checkmark.circle.fill")
                EvidenceStat(count: refuteCount, label: "반박", color: .red, icon: "xmark.circle.fill")
                EvidenceStat(count: discoveryCount, label: "새발견", color: .orange, icon: "lightbulb.fill")
                Spacer()
                Button(action: { showAddEvidence = true }) {
                    Label("증거 추가", systemImage: "plus").font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
            }

            // 증거 목록
            if evidences.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40)).foregroundColor(.secondary.opacity(0.3))
                    Text("책을 읽으며 가설을 지지하거나 반박하는\n문장을 발견하면 증거로 추가하세요")
                        .font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(40)
            } else {
                VStack(spacing: 12) {
                    ForEach(evidences) { evidence in
                        EvidenceCard(evidence: evidence) { removeEvidence(evidence) }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEvidence) {
            AddEvidenceView(hypotheses: book.hypotheses) { evidence in
                if book.session == nil { book.session = ReadingSession() }
                book.session?.evidences.append(evidence)
                book.session?.updatedAt = Date()
            }
        }
        .sheet(isPresented: $showAddRound) {
            AddRoundView { round in
                if book.session == nil { book.session = ReadingSession() }
                book.session?.rounds.append(round)
                book.session?.updatedAt = Date()
            }
        }
    }

    func removeEvidence(_ evidence: Evidence) {
        book.session?.evidences.removeAll { $0.id == evidence.id }
    }
}

// MARK: - Reading Round Card
struct ReadingRoundCard: View {
    let round: ReadingRound

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(round.chapter, systemImage: "book.pages")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                if round.goalAchieved {
                    Label("목표 달성!", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(.green)
                }
            }
            if !round.guess.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("기대:").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                    Text(round.guess).font(.system(size: 11)).foregroundColor(.secondary).italic()
                }
            }
        }
        .padding(12)
        .background(round.goalAchieved ? Color.green.opacity(0.06) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(round.goalAchieved ? Color.green.opacity(0.3) : Color.secondary.opacity(0.1)))
    }
}

// MARK: - Add Round Sheet
struct AddRoundView: View {
    let onAdd: (ReadingRound) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var chapter = ""
    @State private var guess = ""
    @State private var goalAchieved = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .buttonStyle(.plain).foregroundColor(.secondary)
                Spacer()
                Text("읽기 라운드 추가").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("추가") {
                    let round = ReadingRound(chapter: chapter, guess: guess, goalAchieved: goalAchieved)
                    onAdd(round)
                    dismiss()
                }
                .disabled(chapter.isEmpty).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("📖 읽을 장 *").font(.system(size: 13, weight: .medium))
                    Text("목표 달성에 가장 도움될 것 같은 장 하나를 고르세요")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                    TextField("예: 10장 — 최고의 결과를 내는 여섯 가지 변화의 길", text: $chapter)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("🔮 이 장에서 기대하는 것").font(.system(size: 13, weight: .medium))
                    Text("읽기 전에 미리 추측해보세요 — 맞고 틀림은 중요하지 않아요")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                    TextEditor(text: $guess)
                        .font(.system(size: 13)).frame(minHeight: 90)
                        .scrollContentBackground(.hidden).padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                }

                Toggle(isOn: $goalAchieved) {
                    Label("이 장을 읽고 목표를 달성했다", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13))
                }
                .tint(.green)
            }
            .padding(20)

            Spacer()
        }
        .frame(width: 480, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Tab 3: Conclusion
struct ConclusionTab: View {
    @Bindable var book: Book

    var evidences: [Evidence] { book.session?.evidences ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            // 처음 가설들
            if !book.hypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("처음 가설들").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    ForEach(book.hypotheses.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1)")
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.purple)
                                .frame(width: 18, height: 18)
                                .background(Color.purple.opacity(0.1)).clipShape(Circle())
                            Text(book.hypotheses[i])
                                .font(.system(size: 13)).italic().foregroundColor(.primary.opacity(0.85))
                        }
                        .padding(12).background(Color.purple.opacity(0.06)).cornerRadius(8)
                    }
                }
            }

            // 수집한 증거 요약
            if !evidences.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("수집한 증거").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        ForEach(EvidenceType.allCases, id: \.self) { type in
                            let count = evidences.filter { $0.type == type }.count
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                Text("\(count)개")
                            }
                            .font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            SectionHeader(icon: "🔄", title: "수정된 설명", subtitle: "책을 읽고 나서 바뀐 내 답 — 더 나은 설명을 찾았나요?")
            EditableTextArea(
                text: Binding(get: { book.revisedExplanation ?? "" }, set: { book.revisedExplanation = $0 }),
                placeholder: "처음 가설에서 어떻게 달라졌나요?\n책이 새로운 설명을 제시했나요?"
            )

            Divider().opacity(0.5)

            SectionHeader(icon: "🎯", title: "딱 하나의 행동", subtitle: "내일 당장 해볼 수 있는 단 하나의 실천")
            EditableTextArea(
                text: Binding(get: { book.oneAction ?? "" }, set: { book.oneAction = $0 }),
                placeholder: "\"내일 [상황]에서 [행동]을 해볼 것이다\""
            )

            // 멈추기 결정
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                Text("멈추기 결정").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                Text("목표를 달성했거나, 이 책에서 더 얻을 것이 없다면 과감히 덮으세요\n삶은 유한하고 책은 무한합니다.")
                    .font(.system(size: 12)).foregroundColor(.secondary)

                if book.status != .finished {
                    HStack(spacing: 12) {
                        Button(action: {
                            book.status = .finished
                            book.finishedAt = Date()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("목표 달성 — 독서 완료").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            book.status = .abandoned
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("목표 달성 불가 — 책 덮기")
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("완독 완료! \(book.finishedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                            .font(.system(size: 13)).foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Add Evidence Sheet
struct AddEvidenceView: View {
    let hypotheses: [String]
    let onAdd: (Evidence) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var quote = ""
    @State private var page = ""
    @State private var memo = ""
    @State private var selectedType = EvidenceType.supports

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .buttonStyle(.plain).foregroundColor(.secondary)
                Spacer()
                Text("증거 추가").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("추가") {
                    let evidence = Evidence(quote: quote, page: Int(page), type: selectedType, memo: memo)
                    onAdd(evidence)
                    dismiss()
                }
                .disabled(quote.isEmpty).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 가설들 reminder
                    if !hypotheses.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("추적 가설들").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                            ForEach(hypotheses.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 9, weight: .bold)).foregroundColor(.purple)
                                        .frame(width: 16, height: 16)
                                        .background(Color.purple.opacity(0.1)).clipShape(Circle())
                                    Text(hypotheses[i]).font(.system(size: 12)).italic()
                                }
                            }
                        }
                        .padding(10).background(Color.purple.opacity(0.06)).cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("이 문장은 가설과 어떤 관계인가요?")
                            .font(.system(size: 13, weight: .medium))
                        HStack(spacing: 10) {
                            ForEach(EvidenceType.allCases, id: \.self) { type in
                                Button(action: { selectedType = type }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedType == type ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedType == type ? .accentColor : .secondary)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedType == type ? Color.accentColor : Color.clear, lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("발췌 문장 *").font(.system(size: 13, weight: .medium))
                        TextEditor(text: $quote)
                            .font(.system(size: 13)).frame(minHeight: 100)
                            .scrollContentBackground(.hidden).padding(10)
                            .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("페이지").font(.system(size: 13, weight: .medium))
                            TextField("예: 47", text: $page).textFieldStyle(.roundedBorder).frame(width: 100)
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("내 생각").font(.system(size: 13, weight: .medium))
                        TextEditor(text: $memo)
                            .font(.system(size: 13)).frame(minHeight: 80)
                            .scrollContentBackground(.hidden).padding(10)
                            .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 500, height: 580)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(icon).font(.system(size: 18))
                Text(title).font(.system(size: 16, weight: .bold))
            }
            Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary)
        }
    }
}

struct EditableTextArea: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 13)).foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 12).padding(.vertical, 10)
            }
            TextEditor(text: $text)
                .font(.system(size: 13)).frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8).padding(.vertical, 6)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15)))
    }
}

struct EvidenceStat: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text("\(count) \(label)").font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.08)).cornerRadius(20)
    }
}

struct EvidenceCard: View {
    let evidence: Evidence
    let onDelete: () -> Void

    var typeColor: Color {
        switch evidence.type {
        case .supports: return .green
        case .refutes: return .red
        case .newDiscovery: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: evidence.type.icon)
                    Text(evidence.type.rawValue)
                }
                .font(.system(size: 11, weight: .semibold)).foregroundColor(typeColor)
                Spacer()
                if let page = evidence.page {
                    Text("p.\(page)").font(.system(size: 11)).foregroundColor(.secondary)
                }
                Button(action: onDelete) {
                    Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }

            Text("\"\(evidence.quote)\"").font(.system(size: 13)).italic()

            if !evidence.memo.isEmpty {
                Text(evidence.memo).font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(typeColor.opacity(0.05)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(typeColor.opacity(0.2)))
    }
}
