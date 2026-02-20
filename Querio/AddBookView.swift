import SwiftUI

struct AddBookView: View {
    let onAdd: (Book) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0

    // Book info
    @State private var searchQuery = ""
    @State private var searchResults: [KakaoBook] = []
    @State private var isSearching = false
    @State private var selectedKakaoBook: KakaoBook?
    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var useManual = false

    // POR fields
    @State private var phenomenon = ""
    @State private var goal = ""
    @State private var abductiveQuestions: [String] = []
    @State private var currentQuestion = ""
    @State private var hypotheses: [String] = []
    @State private var currentHypothesis = ""
    @State private var suggestedQuestions: [String] = []

    let steps = ["📚 책 선택", "🎯 목표 설정", "❓ 질문들", "💡 가설들"]

    var canProceedStep0: Bool {
        useManual ? (!manualTitle.isEmpty && !manualAuthor.isEmpty) : selectedKakaoBook != nil
    }
    var canProceedStep1: Bool {
        phenomenon.trimmingCharacters(in: .whitespaces).count >= 10 &&
        goal.trimmingCharacters(in: .whitespaces).count >= 5
    }
    var canProceedStep2: Bool {
        !abductiveQuestions.isEmpty || currentQuestion.trimmingCharacters(in: .whitespaces).count >= 5
    }
    var canProceedStep3: Bool {
        !hypotheses.isEmpty || currentHypothesis.trimmingCharacters(in: .whitespaces).count >= 10
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return canProceedStep0
        case 1: return canProceedStep1
        case 2: return canProceedStep2
        default: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .buttonStyle(.plain).foregroundColor(.secondary)
                Spacer()
                Text("새 책 추가").font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("취소").opacity(0)
            }
            .padding(.horizontal, 24).padding(.vertical, 16)

            Divider()

            StepIndicator(steps: steps, currentStep: currentStep)
                .padding(.horizontal, 24).padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    switch currentStep {
                    case 0: step0BookSearch
                    case 1: step1GoalSetting
                    case 2: step2Questions
                    case 3: step3Hypotheses
                    default: EmptyView()
                    }
                }
                .padding(28)
            }

            Divider()

            HStack {
                if currentStep > 0 {
                    Button("← 이전") { currentStep -= 1 }
                        .buttonStyle(.plain).foregroundColor(.secondary)
                }
                Spacer()
                if currentStep < 3 {
                    Button("다음 →") { handleNext() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                } else {
                    Button("독서 시작하기 🚀") { addBook() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceedStep3)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
        }
        .frame(width: 560, height: 640)
        .background(Color(NSColor.windowBackgroundColor))
    }

    func handleNext() {
        if currentStep == 1 {
            generateSuggestedQuestions()
        } else if currentStep == 2 {
            let q = currentQuestion.trimmingCharacters(in: .whitespaces)
            if !q.isEmpty && !abductiveQuestions.contains(q) {
                abductiveQuestions.append(q)
                currentQuestion = ""
            }
        }
        currentStep += 1
    }

    func addBook() {
        let h = currentHypothesis.trimmingCharacters(in: .whitespaces)
        var finalHypotheses = hypotheses
        if !h.isEmpty { finalHypotheses.append(h) }

        let book: Book
        if let kakaoBook = selectedKakaoBook {
            book = Book(
                title: kakaoBook.title,
                author: kakaoBook.authorString,
                coverImageURL: kakaoBook.thumbnail,
                isbn: kakaoBook.isbn,
                phenomenon: phenomenon,
                goal: goal,
                abductiveQuestions: abductiveQuestions,
                hypotheses: finalHypotheses
            )
        } else {
            book = Book(
                title: manualTitle,
                author: manualAuthor,
                phenomenon: phenomenon,
                goal: goal,
                abductiveQuestions: abductiveQuestions,
                hypotheses: finalHypotheses
            )
        }
        book.status = .reading
        book.session = ReadingSession()
        onAdd(book)
        dismiss()
    }

    func generateSuggestedQuestions() {
        let bookTitle = selectedKakaoBook?.title ?? manualTitle
        suggestedQuestions = generateQuestions(combined: phenomenon + " " + goal, bookTitle: bookTitle)
    }

    func generateQuestions(combined: String, bookTitle: String) -> [String] {
        var questions: [String] = []
        let lower = combined.lowercased()

        if lower.contains("시간") || lower.contains("생산") || lower.contains("할 일") {
            questions.append("내가 시간을 제대로 못 쓰는 진짜 원인은 무엇인가?")
            questions.append("생산성의 본질은 더 많이 하는 것인가, 덜 하는 것인가?")
        }
        if lower.contains("사람") || lower.contains("관계") || lower.contains("팀") || lower.contains("리더") {
            questions.append("사람을 움직이는 것은 논리인가, 감정인가?")
            questions.append("신뢰는 어디서 시작되는가?")
        }
        if lower.contains("돈") || lower.contains("경제") || lower.contains("투자") {
            questions.append("나의 돈에 대한 믿음 중 틀린 것은 무엇인가?")
            questions.append("부의 본질은 얼마를 버느냐인가, 얼마를 지키느냐인가?")
        }
        if lower.contains("습관") || lower.contains("변화") || lower.contains("루틴") {
            questions.append("내가 변화에 실패하는 진짜 이유는 무엇인가?")
            questions.append("습관은 의지로 만들어지는가, 환경으로 만들어지는가?")
        }
        if lower.contains("불안") || lower.contains("두려움") || lower.contains("스트레스") {
            questions.append("나의 불안이 실제 위험에서 오는가, 생각에서 오는가?")
            questions.append("감정을 다스린다는 것은 억누르는 것인가, 이해하는 것인가?")
        }
        if questions.isEmpty {
            questions = [
                "이 상황에서 내가 놓치고 있는 핵심은 무엇인가?",
                "지금 내가 겪는 현상의 근본 원인은 무엇인가?",
                "이 문제를 해결한 사람들은 어떻게 생각했는가?",
                "\(bookTitle)이/가 내 상황에 어떤 새로운 시각을 줄 수 있는가?"
            ]
        }
        return Array(questions.prefix(4))
    }

    // MARK: Step 0 - Book Search
    var step0BookSearch: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("📚 어떤 책을 읽을 건가요?")
                    .font(.system(size: 20, weight: .bold))
                Text("책 제목이나 저자를 검색하거나 직접 입력하세요")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }

            Picker("입력 방식", selection: $useManual) {
                Text("책 검색").tag(false)
                Text("직접 입력").tag(true)
            }
            .pickerStyle(.segmented).labelsHidden()

            if useManual {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledTextField(label: "책 제목", placeholder: "예: 아토믹 해빗", text: $manualTitle)
                    LabeledTextField(label: "저자", placeholder: "예: 제임스 클리어", text: $manualAuthor)
                }
            } else {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("책 제목 검색...", text: $searchQuery)
                        .textFieldStyle(.plain).onSubmit { searchBooks() }
                    if isSearching { ProgressView().scaleEffect(0.7) }
                    Button("검색") { searchBooks() }.disabled(searchQuery.isEmpty)
                }
                .padding(10).background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)

                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(searchResults) { kakaoBook in
                                KakaoBookRow(
                                    book: kakaoBook,
                                    isSelected: selectedKakaoBook?.isbn == kakaoBook.isbn
                                ) { selectedKakaoBook = kakaoBook }
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }

                if let selected = selectedKakaoBook {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selected.title).font(.system(size: 13, weight: .medium))
                            Text(selected.authorString).font(.system(size: 12)).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("변경") { selectedKakaoBook = nil }
                            .buttonStyle(.plain).font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    .padding(12).background(Color.green.opacity(0.08)).cornerRadius(10)
                }
            }
        }
    }

    func searchBooks() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        searchResults = []

        var components = URLComponents(string: "https://dapi.kakao.com/v3/search/book")!
        components.queryItems = [URLQueryItem(name: "query", value: searchQuery), URLQueryItem(name: "size", value: "10")]

        var request = URLRequest(url: components.url!)
        request.setValue("KakaoAK b1bd9fc38d1a62a5700f648728e1d0f0", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                isSearching = false
                guard let data else { return }
                if let result = try? JSONDecoder().decode(KakaoBookSearchResult.self, from: data) {
                    searchResults = result.documents
                }
            }
        }.resume()
    }

    // MARK: Step 1 - 목표 설정
    var step1GoalSetting: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("🎯 목표 설정")
                    .font(.system(size: 20, weight: .bold))
                Text("지금 내 삶의 현상을 파악하고\n이 책으로 달성하고 싶은 목표를 정하세요")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🔍 내 삶의 현상").font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(phenomenon.count)자").font(.system(size: 11))
                        .foregroundColor(phenomenon.count >= 10 ? .green : .secondary)
                }
                Text("이 책을 집어든 이유. 요즘 불편하거나 해결되지 않는 것을 써보세요")
                    .font(.system(size: 12)).foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["팀원들이 내 말을 안 따른다", "매일 할 일을 못 끝낸다", "아침마다 의욕이 없다"], id: \.self) { hint in
                            Button(hint) { phenomenon = hint }
                                .buttonStyle(.plain).font(.system(size: 11))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.08))
                                .foregroundColor(.accentColor).cornerRadius(20)
                        }
                    }
                }

                ZStack(alignment: .topLeading) {
                    if phenomenon.isEmpty {
                        Text("요즘 내 삶에서 이상하거나 불편한 것...")
                            .font(.system(size: 13)).foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 12).padding(.vertical, 10)
                    }
                    TextEditor(text: $phenomenon)
                        .font(.system(size: 13)).frame(minHeight: 90)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2)))
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎯 목표").font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(goal.count)자").font(.system(size: 11))
                        .foregroundColor(goal.count >= 5 ? .green : .secondary)
                }
                Text("이 책을 다 활용했을 때 어떤 상태가 되어 있고 싶나요?")
                    .font(.system(size: 12)).foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    if goal.isEmpty {
                        Text("\"[상황]에서 [행동]할 수 있게 되고 싶다\" 형식으로 써보세요")
                            .font(.system(size: 13)).foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 12).padding(.vertical, 10)
                    }
                    TextEditor(text: $goal)
                        .font(.system(size: 13)).frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2)))
            }

            if phenomenon.count >= 10 && goal.count >= 5 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("좋아요! 목표가 명확할수록 필요한 부분을 정확히 찾을 수 있어요")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: Step 2 - 질문들
    var step2Questions: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("❓ 귀추적 질문들")
                    .font(.system(size: 20, weight: .bold))
                Text("현상과 목표에서 출발해 탐색할 질문들을 만드세요\n질문이 많을수록 다양한 각도로 책을 파고들 수 있어요")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.bubble.fill").foregroundColor(.accentColor.opacity(0.7))
                    Text(phenomenon).font(.system(size: 12)).foregroundColor(.secondary).italic()
                }
                if !goal.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "scope").foregroundColor(.green.opacity(0.8))
                        Text("목표: \(goal)").font(.system(size: 12)).foregroundColor(.green.opacity(0.8))
                    }
                }
            }
            .padding(12).background(Color.accentColor.opacity(0.05)).cornerRadius(8)

            if !suggestedQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("✨ 추천 질문 (탭하여 추가/해제)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)

                    ForEach(suggestedQuestions, id: \.self) { q in
                        let isAdded = abductiveQuestions.contains(q)
                        Button(action: {
                            if isAdded { abductiveQuestions.removeAll { $0 == q } }
                            else { abductiveQuestions.append(q) }
                        }) {
                            HStack {
                                Text(q).font(.system(size: 13)).foregroundColor(.primary).multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundColor(isAdded ? .accentColor : .secondary)
                            }
                            .padding(12)
                            .background(isAdded ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isAdded ? Color.accentColor : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !abductiveQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("추가된 질문 (\(abductiveQuestions.count)개)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)

                    ForEach(abductiveQuestions.indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.accentColor)
                                .frame(width: 20, height: 20)
                                .background(Color.accentColor.opacity(0.1)).clipShape(Circle())
                            Text(abductiveQuestions[i]).font(.system(size: 13))
                            Spacer()
                            Button(action: { abductiveQuestions.remove(at: i) }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary.opacity(0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(abductiveQuestions.isEmpty ? "질문 입력 *" : "질문 추가")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                HStack(alignment: .bottom, spacing: 8) {
                    TextEditor(text: $currentQuestion)
                        .font(.system(size: 13)).frame(minHeight: 60)
                        .scrollContentBackground(.hidden).padding(8)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    Button(action: addCurrentQuestion) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22))
                            .foregroundColor(currentQuestion.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentQuestion.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    func addCurrentQuestion() {
        let q = currentQuestion.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        if !abductiveQuestions.contains(q) { abductiveQuestions.append(q) }
        currentQuestion = ""
    }

    // MARK: Step 3 - 가설들
    var step3Hypotheses: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("💡 나의 가설들")
                    .font(.system(size: 20, weight: .bold))
                Text("책을 읽기 **전에** 내 답을 먼저 적어보세요\n가설이 많을수록 증거 추적이 더 날카로워져요")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }

            if !abductiveQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("탐색할 질문들")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                    ForEach(abductiveQuestions.prefix(3), id: \.self) { q in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 11)).foregroundColor(.orange.opacity(0.8))
                            Text(q).font(.system(size: 12)).foregroundColor(.secondary).italic()
                        }
                    }
                    if abductiveQuestions.count > 3 {
                        Text("외 \(abductiveQuestions.count - 3)개 더...")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                    }
                }
                .padding(12).background(Color.orange.opacity(0.05)).cornerRadius(8)
            }

            if !hypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("추가된 가설 (\(hypotheses.count)개)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)

                    ForEach(hypotheses.indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.purple)
                                .frame(width: 20, height: 20)
                                .background(Color.purple.opacity(0.1)).clipShape(Circle())
                            Text(hypotheses[i]).font(.system(size: 13))
                            Spacer()
                            Button(action: { hypotheses.remove(at: i) }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary.opacity(0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(hypotheses.isEmpty ? "가설 입력 *" : "가설 추가")
                        .font(.system(size: 13, weight: .medium))
                    Text("(틀려도 괜찮아요)").font(.system(size: 11)).foregroundColor(.secondary)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if currentHypothesis.isEmpty {
                            Text("\"아마도... 왜냐하면...\" 형식으로 써보세요")
                                .font(.system(size: 13)).foregroundColor(.secondary.opacity(0.6))
                                .padding(.horizontal, 12).padding(.vertical, 10)
                        }
                        TextEditor(text: $currentHypothesis)
                            .font(.system(size: 13)).frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 8).padding(.vertical, 6)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2)))

                    Button(action: addCurrentHypothesis) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22))
                            .foregroundColor(currentHypothesis.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .purple)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentHypothesis.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                HStack(spacing: 8) {
                    ForEach(["아마도 나는...", "내 생각엔...", "이 책이..."], id: \.self) { starter in
                        Button(starter) {
                            if currentHypothesis.isEmpty { currentHypothesis = starter + " " }
                        }
                        .buttonStyle(.plain).font(.system(size: 11))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(20)
                    }
                }
            }

            if !hypotheses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                    Text("독서 여정").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    HStack(spacing: 0) {
                        JourneyStep(icon: "🔍", label: "현상", color: .blue)
                        Arrow()
                        JourneyStep(icon: "🎯", label: "목표", color: .green)
                        Arrow()
                        JourneyStep(icon: "❓", label: "질문들", color: .orange)
                        Arrow()
                        JourneyStep(icon: "💡", label: "가설들", color: .purple)
                        Arrow()
                        JourneyStep(icon: "📖", label: "독서", color: .accentColor)
                    }
                }
            }
        }
    }

    func addCurrentHypothesis() {
        let h = currentHypothesis.trimmingCharacters(in: .whitespaces)
        guard !h.isEmpty else { return }
        hypotheses.append(h)
        currentHypothesis = ""
    }
}

// MARK: - Sub Components

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            TextField(placeholder, text: $text).textFieldStyle(.roundedBorder)
        }
    }
}

struct KakaoBookRow: View {
    let book: KakaoBook
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Group {
                    if let url = URL(string: book.thumbnail), !book.thumbnail.isEmpty {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.12))
                                .overlay(Text(String(book.title.prefix(1))).font(.system(size: 16, weight: .bold)).foregroundColor(.accentColor))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.12))
                            .overlay(Text(String(book.title.prefix(1))).font(.system(size: 16, weight: .bold)).foregroundColor(.accentColor))
                    }
                }
                .frame(width: 36, height: 50).cornerRadius(4).clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text(book.title).font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                    Text(book.authorString).font(.system(size: 11)).foregroundColor(.secondary)
                    Text(book.publisher).font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct JourneyStep: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 18))
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(color)
        }
        .frame(width: 46)
    }
}

struct Arrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.4)).frame(width: 16)
    }
}

struct StepIndicator: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(i <= currentStep ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .frame(width: 26, height: 26)
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(i <= currentStep ? .white : .secondary)
                        }
                        Text(steps[i]).font(.system(size: 10))
                            .foregroundColor(i == currentStep ? .accentColor : .secondary).lineLimit(1)
                    }
                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(i < currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(height: 2).frame(maxWidth: .infinity).padding(.bottom, 16)
                    }
                }
            }
        }
    }
}
