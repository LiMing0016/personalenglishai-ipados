import SwiftUI

struct WritingHubView: View {
    @Binding var selectedDraftID: String?
    @State private var state = WritingHubState()

    var body: some View {
        GeometryReader { proxy in
            let layout = WritingHubLayout(containerWidth: proxy.size.width)

            ScrollView {
                VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                    WritingHubTopArea(
                        selectedSection: $state.selectedSection,
                        layout: layout
                    )

                    switch state.selectedSection {
                    case .practice:
                        WritingPracticeHub(
                            state: $state,
                            selectedDraftID: $selectedDraftID,
                            layout: layout
                        )
                    case .dashboard:
                        WritingDashboardHub(summary: state.dashboardSummary)
                    }
                }
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, 38)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WritingHubPalette.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: WritingHubRoute.self) { route in
            switch route {
            case .editor(let draftID, let mode):
                WritingRootView(draftID: draftID, initialMode: mode)
            }
        }
        .accessibilityIdentifier("writing.hub")
    }
}

private enum WritingHubRoute: Hashable {
    case editor(draftID: String?, mode: WritingMode)
}

private enum WritingHubPalette {
    static let background = Color(red: 0.965, green: 0.955, blue: 0.925)
    static let panel = Color(red: 0.992, green: 0.985, blue: 0.960)
    static let paper = Color(red: 0.998, green: 0.995, blue: 0.982)
    static let border = Color(red: 0.855, green: 0.815, blue: 0.735)
    static let text = Color(red: 0.11, green: 0.105, blue: 0.095)
    static let muted = Color(red: 0.48, green: 0.45, blue: 0.39)
    static let green = Color(red: 0.24, green: 0.56, blue: 0.48)
    static let blue = Color(red: 0.20, green: 0.44, blue: 0.82)
    static let gold = Color(red: 0.70, green: 0.55, blue: 0.22)
}

private struct WritingHubTopArea: View {
    @Binding var selectedSection: WritingHubSection
    let layout: WritingHubLayout

    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            HStack(alignment: .top) {
                WritingSectionTabs(selectedSection: $selectedSection)
                    .accessibilityIdentifier("writing.hub.sectionPicker")

                Spacer()

                WritingNewEssayMenu()
            }

            HStack(alignment: .center, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("PEAI WRITING / PRACTICE")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(WritingHubPalette.muted)
                        .tracking(0.8)

                    Text("写作练习")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(WritingHubPalette.text)

                    Text("坚持每天写一点，英语写作自然进步。")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(WritingHubPalette.muted)
                }

                Spacer()

                if layout.showsHeroIllustration {
                    WritingLineIllustration()
                        .frame(width: 220, height: 104)
                        .padding(.trailing, 40)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

private struct WritingSectionTabs: View {
    @Binding var selectedSection: WritingHubSection

    var body: some View {
        HStack(spacing: 28) {
            ForEach(WritingHubSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(selectedSection == section ? WritingHubPalette.text : WritingHubPalette.muted)

                        Rectangle()
                            .fill(selectedSection == section ? WritingHubPalette.text : Color.clear)
                            .frame(width: section == .practice ? 56 : 84, height: 2)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("writing.hub.section.\(section.rawValue)")
            }
        }
    }
}

private struct WritingNewEssayMenu: View {
    var body: some View {
        Menu {
            NavigationLink(value: WritingHubRoute.editor(draftID: nil, mode: .free)) {
                Label("自由写作", systemImage: "square.and.pencil")
            }

            NavigationLink(value: WritingHubRoute.editor(draftID: nil, mode: .exam)) {
                Label("考试写作", systemImage: "timer")
            }
        } label: {
            HStack(spacing: 0) {
                Text("+ 新建作文")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 20)
                    .frame(height: 52)

                Divider()
                    .frame(height: 52)
                    .overlay(Color.white.opacity(0.22))

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 52, height: 52)
            }
            .foregroundStyle(.white)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("writing.hub.new.menu")
    }
}

private struct WritingLineIllustration: View {
    var body: some View {
        Canvas { context, size in
            var pen = Path()
            pen.move(to: CGPoint(x: size.width * 0.82, y: size.height * 0.22))
            pen.addLine(to: CGPoint(x: size.width * 0.98, y: size.height * 0.38))
            pen.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.92))
            pen.closeSubpath()

            let paper = Path(roundedRect: CGRect(x: size.width * 0.36, y: size.height * 0.14, width: size.width * 0.48, height: size.height * 0.70), cornerRadius: 12)
            var wind = Path()
            wind.move(to: CGPoint(x: size.width * 0.10, y: size.height * 0.42))
            wind.addCurve(
                to: CGPoint(x: size.width * 0.34, y: size.height * 0.40),
                control1: CGPoint(x: size.width * 0.17, y: size.height * 0.28),
                control2: CGPoint(x: size.width * 0.24, y: size.height * 0.56)
            )
            wind.move(to: CGPoint(x: size.width * 0.04, y: size.height * 0.63))
            wind.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.63))
            wind.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.78))
            wind.addCurve(
                to: CGPoint(x: size.width * 0.58, y: size.height * 0.80),
                control1: CGPoint(x: size.width * 0.26, y: size.height * 0.62),
                control2: CGPoint(x: size.width * 0.45, y: size.height * 0.96)
            )

            var lines = Path()
            lines.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.36))
            lines.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.36))
            lines.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.53))
            lines.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.53))
            lines.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.70))
            lines.addLine(to: CGPoint(x: size.width * 0.68, y: size.height * 0.70))

            context.stroke(wind, with: .color(WritingHubPalette.muted), lineWidth: 3)
            context.stroke(paper, with: .color(WritingHubPalette.muted), lineWidth: 3)
            context.stroke(lines, with: .color(WritingHubPalette.muted), lineWidth: 3)
            context.stroke(pen, with: .color(WritingHubPalette.muted), lineWidth: 3)
        }
    }
}

private struct WritingPracticeHub: View {
    @Binding var state: WritingHubState
    @Binding var selectedDraftID: String?
    let layout: WritingHubLayout

    var body: some View {
        Group {
            if layout.showsDailyPromptAside {
                HStack(alignment: .top, spacing: 28) {
                    WritingArchivePanel(
                        state: $state,
                        selectedDraftID: $selectedDraftID,
                        layout: layout
                    )
                    .frame(maxWidth: .infinity, minHeight: 620)

                    WritingDailyPromptPanel()
                        .frame(width: layout.dailyPromptWidth)
                        .frame(minHeight: 620)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    WritingArchivePanel(
                        state: $state,
                        selectedDraftID: $selectedDraftID,
                        layout: layout
                    )
                    .frame(maxWidth: .infinity, minHeight: 520)

                    WritingDailyPromptPanel()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityIdentifier("writing.hub.section.practice")
    }
}

private struct WritingArchivePanel: View {
    @Binding var state: WritingHubState
    @Binding var selectedDraftID: String?
    let layout: WritingHubLayout

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if layout.isCompact {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("ARCHIVE")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(WritingHubPalette.muted)
                        .tracking(0.8)

                    Text("历史作文")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(WritingHubPalette.text)
                }

                WritingArchiveControls(
                    state: $state,
                    searchFieldWidth: layout.searchFieldWidth,
                    alignment: .leading
                )
            } else {
                HStack(alignment: .top, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("ARCHIVE")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(WritingHubPalette.muted)
                            .tracking(0.8)

                        Text("历史作文")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(WritingHubPalette.text)
                    }

                    Spacer()

                    WritingArchiveControls(
                        state: $state,
                        searchFieldWidth: layout.searchFieldWidth,
                        alignment: .trailing
                    )
                }
            }

            if state.filteredDocuments.isEmpty {
                WritingHubEmptyState(
                    title: "没有找到作文",
                    message: "换一个关键词，或切换到全部类型看看。"
                )
                .frame(maxWidth: .infinity, minHeight: 320)
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: Spacing.md),
                        count: layout.documentColumnCount
                    ),
                    spacing: Spacing.md
                ) {
                    ForEach(state.filteredDocuments) { document in
                        NavigationLink(value: WritingHubRoute.editor(draftID: document.id, mode: document.mode)) {
                            WritingDocumentCard(document: document)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedDraftID = document.id
                        })
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("writing.hub.document.\(document.id)")
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(WritingHubPalette.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct WritingArchiveControls: View {
    @Binding var state: WritingHubState
    let searchFieldWidth: CGFloat
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                WritingDocumentSearchField(text: $state.searchText, width: searchFieldWidth)

                Picker("作文类型", selection: $state.modeFilter) {
                    ForEach(WritingDocumentModeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 196)
                .accessibilityIdentifier("writing.hub.modeFilter")
            }

            Menu {
                Button("最近修改", systemImage: "clock") {}
                Button("最新评分", systemImage: "star") {}
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("最近修改")
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WritingHubPalette.muted)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(WritingHubPalette.paper, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct WritingDocumentSearchField: View {
    @Binding var text: String
    let width: CGFloat

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(red: 0.60, green: 0.62, blue: 0.66))

            TextField("搜索作文标题或关键词...", text: $text)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Spacing.md)
        .frame(width: width, height: 44)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
        .accessibilityIdentifier("writing.hub.search")
    }
}

private struct WritingDocumentCard: View {
    let document: WritingDocumentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                WritingStatusBadge(title: document.mode == .exam ? "考试" : "自由", color: modeColor)
                WritingStatusBadge(title: document.status.title, color: statusColor)
                Spacer()
                Text(relativeUpdatedAt)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WritingHubPalette.muted.opacity(0.72))
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(document.title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(WritingHubPalette.text)
                    .lineLimit(1)

                Text(document.preview)
                    .font(.subheadline)
                    .foregroundStyle(WritingHubPalette.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(WritingHubPalette.border.opacity(0.54))

            HStack(spacing: Spacing.md) {
                WritingDocumentMetric(title: "评分次数", value: "\(document.evaluationCount)")
                WritingDocumentMetric(title: "较初评", value: document.latestScore.map(String.init) ?? "--")
                WritingDocumentMetric(title: "最近修改", value: relativeUpdatedAt)
            }

            Text(document.status == .pendingReview ? "提交评分，生成讲评和修改建议。" : "查看评分记录")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WritingHubPalette.muted)
                .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 242, alignment: .topLeading)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 18, x: 0, y: 12)
    }

    private var modeColor: Color {
        document.mode == .exam ? WritingHubPalette.blue : WritingHubPalette.green
    }

    private var statusColor: Color {
        switch document.status {
        case .draft:
            WritingHubPalette.muted
        case .pendingReview:
            WritingHubPalette.gold
        case .reviewed:
            WritingHubPalette.green
        }
    }

    private var relativeUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: document.updatedAt, relativeTo: Date())
    }
}

private struct WritingStatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.13), in: Capsule())
    }
}

private struct WritingDocumentMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(WritingHubPalette.muted.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(WritingHubPalette.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(WritingHubPalette.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct WritingDailyPromptPanel: View {
    private let prompts = WritingDailyPrompt.samples

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("DAILY")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(WritingHubPalette.muted)
                        .tracking(0.8)
                    Text("每日推荐作文")
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundStyle(WritingHubPalette.text)
                }

                Spacer()

                Button {
                } label: {
                    Label("换一换", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WritingHubPalette.muted)
                }
                .buttonStyle(.plain)
            }

            ForEach(prompts) { prompt in
                WritingDailyPromptCard(prompt: prompt)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(WritingHubPalette.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct WritingDailyPromptCard: View {
    let prompt: WritingDailyPrompt

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                WritingStatusBadge(title: prompt.level, color: WritingHubPalette.gold)
                WritingStatusBadge(title: prompt.genre, color: WritingHubPalette.green)
                Spacer()
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(prompt.title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(WritingHubPalette.text)
                    .lineLimit(2)

                Text(prompt.description)
                    .font(.subheadline)
                    .foregroundStyle(WritingHubPalette.muted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("推荐字数：\(prompt.wordCount)")
                Text("预计用时：\(prompt.duration)")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(WritingHubPalette.muted)

            NavigationLink(value: WritingHubRoute.editor(draftID: nil, mode: .exam)) {
                Text("开始练习")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WritingHubPalette.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(WritingHubPalette.background, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct WritingDailyPrompt: Identifiable {
    let id: String
    let level: String
    let genre: String
    let title: String
    let description: String
    let wordCount: String
    let duration: String

    static let samples = [
        WritingDailyPrompt(
            id: "technology-life",
            level: "中等",
            genre: "议论文",
            title: "科技让生活更美好吗？",
            description: "科技发展在带来便利的同时，也可能带来新的问题。你认为科技让生活更美好吗？为什么？",
            wordCount: "120-180 词",
            duration: "30 分钟"
        ),
        WritingDailyPrompt(
            id: "phone-time-chart",
            level: "中等",
            genre: "图表作文",
            title: "手机使用时间变化趋势图",
            description: "根据图表描述不同年龄段人群每天使用手机的平均时间，并分析原因和影响。",
            wordCount: "120-180 词",
            duration: "30 分钟"
        ),
        WritingDailyPrompt(
            id: "application-email",
            level: "简单",
            genre: "应用文",
            title: "给学校社团写一封申请邮件",
            description: "说明你为什么想加入社团，以及你能为社团带来什么。",
            wordCount: "80-120 词",
            duration: "20 分钟"
        )
    ]
}

private struct WritingDashboardHub: View {
    let summary: WritingHubDashboardSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                WritingDashboardMetricCard(title: "作文总数", value: "\(summary.documentCount)")
                WritingDashboardMetricCard(title: "待评分", value: "\(summary.pendingReviewCount)")
                WritingDashboardMetricCard(title: "平均分", value: summary.averageScoreText)
                WritingDashboardMetricCard(title: "最好成绩", value: summary.bestScoreText)
            }

            WritingHubEmptyState(
                title: "Dashboard 数据接口已预留",
                message: "后端的 /api/writing/dashboard 接入后，这里会展示评分趋势、修改次数和写作成长曲线。"
            )
            .frame(minHeight: 300)
            .background(WritingHubPalette.paper, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
            }
        }
        .accessibilityIdentifier("writing.hub.section.dashboard")
    }
}

private struct WritingDashboardMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(value)
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(WritingHubPalette.text)
                .monospacedDigit()
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WritingHubPalette.muted)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(WritingHubPalette.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(WritingHubPalette.border.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct WritingHubEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(WritingHubPalette.muted.opacity(0.7))
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(WritingHubPalette.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(WritingHubPalette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

struct WritingHubView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WritingHubPreview()
        }
    }
}

private struct WritingHubPreview: View {
    @State private var selectedDraftID: String?

    var body: some View {
        WritingHubView(selectedDraftID: $selectedDraftID)
    }
}
