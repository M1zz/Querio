import SwiftUI

// MARK: - Adaptive Color Extension
// 눈에 편안한 초록 색조 — Light/Dark 모드 자동 전환

extension Color {
    /// 주 창 배경 (흰색 대체) — 아침 숲 안개
    static let gardenWindow = Color(NSColor(name: "gardenWindow") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.11, green: 0.17, blue: 0.11, alpha: 1)   // 짙은 숲 어둠
            : NSColor(red: 0.93, green: 0.96, blue: 0.92, alpha: 1)   // 아침 안개 초록
    })

    /// 카드·입력창 배경 (controlBackground 대체) — 이끼 표면
    static let gardenSurface = Color(NSColor(name: "gardenSurface") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.14, green: 0.21, blue: 0.14, alpha: 1)   // 이끼 그늘
            : NSColor(red: 0.90, green: 0.94, blue: 0.89, alpha: 1)   // 연한 세이지
    })

    /// 시트·팝업 배경 — 열린 온실
    static let gardenElevated = Color(NSColor(name: "gardenElevated") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.17, green: 0.25, blue: 0.17, alpha: 1)   // 온실 어둠
            : NSColor(red: 0.96, green: 0.98, blue: 0.95, alpha: 1)   // 옅은 이슬
    })
}

// MARK: - Garden Color System

struct GardenColors {
    // 흙과 화분
    static let terracotta   = Color(red: 0.70, green: 0.42, blue: 0.22)
    static let clay         = Color(red: 0.56, green: 0.32, blue: 0.16)
    static let darkEarth    = Color(red: 0.32, green: 0.20, blue: 0.08)

    // 성장의 초록
    static let sprout       = Color(red: 0.35, green: 0.68, blue: 0.28)
    static let leaf         = Color(red: 0.20, green: 0.62, blue: 0.18)
    static let canopy       = Color(red: 0.12, green: 0.55, blue: 0.12)

    // 계절 배경 (식물 카드 영역 — Light/Dark 적응형)
    static let morningMist = Color(NSColor(name: "morningMist") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.14, green: 0.23, blue: 0.14, alpha: 1)   // 읽고 싶음 — 밤 새싹
            : NSColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 1)   // 아침 이슬
    })
    static let freshDew = Color(NSColor(name: "freshDew") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.17, green: 0.28, blue: 0.17, alpha: 1)   // 읽는 중 — 달빛 잎새
            : NSColor(red: 0.89, green: 0.96, blue: 0.89, alpha: 1)   // 신선한 이슬
    })
    static let afternoon = Color(NSColor(name: "afternoon") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.15, green: 0.26, blue: 0.15, alpha: 1)   // 완독 — 숲속 그늘
            : NSColor(red: 0.86, green: 0.94, blue: 0.86, alpha: 1)   // 한낮 정원
    })
    static let autumnEarth = Color(NSColor(name: "autumnEarth") { app in
        app.bestMatch(from: [.darkAqua]) == .darkAqua
            ? NSColor(red: 0.22, green: 0.18, blue: 0.15, alpha: 1)   // 포기 — 늦가을 흙
            : NSColor(red: 0.93, green: 0.90, blue: 0.87, alpha: 1)   // 가을 흙
    })

    // 강조
    static let harvest      = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let wilted       = Color(red: 0.52, green: 0.40, blue: 0.22)

    static func background(for status: BookStatus) -> Color {
        switch status {
        case .wantToRead: return morningMist
        case .reading:    return freshDew
        case .finished:   return afternoon
        case .abandoned:  return autumnEarth
        }
    }
}

// MARK: - MoodboardView

struct MoodboardView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    divider
                    colorSection
                    divider
                    growthSection
                    divider
                    typographySection
                    Spacer(minLength: 32)
                }
            }
            .background(moodBackground)

            // 닫기
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .frame(width: 780, height: 660)
    }

    private var divider: some View {
        Divider()
            .overlay(GardenColors.leaf.opacity(0.15))
            .padding(.vertical, 32)
            .padding(.horizontal, 40)
    }

    // 전체 배경 — 정원 안개 그라디언트
    private var moodBackground: some View {
        LinearGradient(
            stops: [
                .init(color: GardenColors.morningMist.opacity(0.6), location: 0),
                .init(color: Color.gardenWindow, location: 0.4),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(alignment: .center, spacing: 40) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("정원의 미학")
                        .font(.system(size: 34, weight: .bold))
                    Text("Querio Garden Moodboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GardenColors.leaf)
                        .tracking(0.5)
                }

                Text("한 권의 책은 씨앗입니다.\n읽고, 질문하고, 증거를 모으는 여정이\n당신만의 고요한 숲을 만들어 나갑니다.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)

                HStack(spacing: 8) {
                    ForEach(["성장", "고요", "발견", "통찰"], id: \.self) { word in
                        Text(word)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(GardenColors.leaf.opacity(0.10))
                            .foregroundColor(GardenColors.canopy)
                            .cornerRadius(20)
                    }
                }
            }

            Spacer()

            // 미니 숲 미리보기
            HStack(alignment: .bottom, spacing: 8) {
                miniPlantCard(status: .wantToRead, evidence: 0, rounds: 0)
                miniPlantCard(status: .reading,    evidence: 4, rounds: 2)
                miniPlantCard(status: .finished,   evidence: 12, rounds: 5)
                miniPlantCard(status: .abandoned,  evidence: 2, rounds: 1)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 8)
    }

    private func miniPlantCard(status: BookStatus, evidence: Int, rounds: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(GardenColors.background(for: status))
                .frame(width: 76, height: 100)
            PlantIllustration(status: status, evidenceCount: evidence, roundCount: rounds)
                .scaleEffect(0.78)
                .frame(width: 76, height: 100)
                .clipped()
        }
    }

    // MARK: - Color Palette

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("컬러 팔레트")

            HStack(alignment: .top, spacing: 0) {
                colorGroup(title: "흙과 화분", swatches: [
                    ColorSwatch("테라코타", GardenColors.terracotta, "#B36B38"),
                    ColorSwatch("마모된 점토", GardenColors.clay, "#8F5229"),
                    ColorSwatch("검은 흙", GardenColors.darkEarth, "#523415"),
                ])

                Spacer()

                colorGroup(title: "성장의 초록", swatches: [
                    ColorSwatch("새싹", GardenColors.sprout, "#59AE47"),
                    ColorSwatch("잎사귀", GardenColors.leaf, "#33A02E"),
                    ColorSwatch("수관", GardenColors.canopy, "#1E8C1E"),
                ])

                Spacer()

                colorGroup(title: "계절 배경", swatches: [
                    ColorSwatch("아침 이슬", GardenColors.morningMist, "#EDF7ED"),
                    ColorSwatch("싱그러움", GardenColors.freshDew, "#E3F5E3"),
                    ColorSwatch("한낮 정원", GardenColors.afternoon, "#DBF0DB"),
                    ColorSwatch("가을 흙", GardenColors.autumnEarth, "#EDE7DE"),
                ])

                Spacer()

                colorGroup(title: "강조색", swatches: [
                    ColorSwatch("수확", GardenColors.harvest, "#FF9500"),
                    ColorSwatch("시든 잎", GardenColors.wilted, "#856637"),
                ])
            }
        }
        .padding(.horizontal, 40)
    }

    private func colorGroup(title: String, swatches: [ColorSwatch]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(swatches) { swatch in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(swatch.color)
                            .frame(width: 32, height: 32)
                            .shadow(color: swatch.color.opacity(0.4), radius: 4, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(swatch.name)
                                .font(.system(size: 12, weight: .medium))
                            Text(swatch.hex)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Growth Stages

    private let stages: [GrowthStage] = [
        GrowthStage(0, .wantToRead, 0,  0, "씨앗",       "막 심어진\n가능성"),
        GrowthStage(1, .reading,    3,  2, "새싹",       "질문이\n싹트기 시작"),
        GrowthStage(2, .reading,    8,  4, "성장 중",    "증거가\n잎을 틔운다"),
        GrowthStage(3, .finished,   14, 5, "만개",       "통찰의\n열매를 맺다"),
        GrowthStage(4, .abandoned,  2,  1, "시듦",       "멈춘 채로\n기억된다"),
    ]

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("성장 단계")

            HStack(alignment: .top, spacing: 0) {
                ForEach(stages) { stage in
                    VStack(spacing: 0) {
                        // 식물 카드
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GardenColors.background(for: stage.status))
                            PlantIllustration(
                                status: stage.status,
                                evidenceCount: stage.evidenceCount,
                                roundCount: stage.roundCount
                            )
                            .scaleEffect(0.82)
                        }
                        .frame(width: 108, height: 112)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GardenColors.leaf.opacity(0.18), lineWidth: 0.5)
                        )

                        // 레이블
                        VStack(spacing: 3) {
                            Text(stage.label)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.top, 10)
                            Text(stage.description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        .frame(width: 100)
                    }

                    if stage.id < stages.count - 1 {
                        VStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(GardenColors.leaf.opacity(0.4))
                                .padding(.bottom, 64)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("타이포그래피")

            VStack(alignment: .leading, spacing: 0) {
                typoRow(label: "21  Bold", preview: AnyView(
                    Text("Querio")
                        .font(.system(size: 21, weight: .bold))
                ))
                typoDivider
                typoRow(label: "13  Semibold", preview: AnyView(
                    Text("클린코드 — 로버트 마틴")
                        .font(.system(size: 13, weight: .semibold))
                ))
                typoDivider
                typoRow(label: "13  Regular", preview: AnyView(
                    Text("읽기 전, 내 삶의 현상을 먼저 정의한다")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                ))
                typoDivider
                typoRow(label: "12  Regular", preview: AnyView(
                    Text("로버트 마틴 · 완독 2024.01")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                ))
                typoDivider
                typoRow(label: "11  Regular", preview: AnyView(
                    HStack(spacing: 10) {
                        Label("14", systemImage: "leaf.fill")
                            .foregroundColor(GardenColors.leaf)
                        Label("5라운드", systemImage: "arrow.clockwise")
                            .foregroundColor(.secondary)
                        Text("완독")
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    .font(.system(size: 11))
                ))
            }
            .padding(20)
            .background(Color.gardenSurface.opacity(0.8))
            .cornerRadius(12)
        }
        .padding(.horizontal, 40)
    }

    private func typoRow(label: String, preview: AnyView) -> some View {
        HStack(spacing: 20) {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)

            preview
        }
        .padding(.vertical, 12)
    }

    private var typoDivider: some View {
        Divider().opacity(0.4)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
    }
}

// MARK: - Data Models (local)

struct ColorSwatch: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let hex: String
    init(_ name: String, _ color: Color, _ hex: String) {
        self.name = name; self.color = color; self.hex = hex
    }
}

struct GrowthStage: Identifiable {
    let id: Int
    let status: BookStatus
    let evidenceCount: Int
    let roundCount: Int
    let label: String
    let description: String
    init(_ id: Int, _ status: BookStatus, _ ev: Int, _ ro: Int, _ label: String, _ desc: String) {
        self.id = id; self.status = status; self.evidenceCount = ev
        self.roundCount = ro; self.label = label; self.description = desc
    }
}
