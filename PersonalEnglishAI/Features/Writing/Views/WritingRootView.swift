import SwiftUI

struct WritingRootView: View {
    let draftID: String?
    @State private var mode: WritingMode
    @State private var prompt = ""
    @State private var essay = ""
    @State private var selectedTool: WritingAssistantTool?
    @State private var evaluationResponse: WritingEvaluateResponse?
    @State private var isEvaluating = false
    @State private var evaluationError: String?
    @State private var saveStatus: WritingSaveStatus = .saved
    @State private var autosaveTask: Task<Void, Never>?
    @State private var isFocusMode = false
    @State private var wordGoal = 500
    @Environment(\.dismiss) private var dismiss

    private let writingService = MockWritingService()

    init(draftID: String?, initialMode: WritingMode = .free) {
        self.draftID = draftID
        _mode = State(initialValue: initialMode)
    }

    private var metrics: WritingDocumentMetrics {
        WritingDocumentMetrics(text: essay)
    }

    private var goalProgress: WritingGoalProgress {
        WritingGoalProgress(metrics: metrics, targetWordCount: wordGoal)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    WritingTopBar(
                        mode: $mode,
                        metrics: metrics,
                        goalProgress: goalProgress,
                        saveStatus: saveStatus,
                        isFocusMode: isFocusMode,
                        clear: clearDraft,
                        submit: evaluateDraft,
                        toggleFocus: { isFocusMode.toggle() },
                        back: { dismiss() }
                    )
                    .padding(.horizontal, isFocusMode ? Spacing.lg : Spacing.xl)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                    .opacity(isFocusMode ? 0.72 : 1)
                }

                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(spacing: 0) {
                        if mode == .exam, !isFocusMode {
                            WritingPromptBar(prompt: $prompt)
                                .padding(.bottom, Spacing.md)
                        }

                        WritingWorkspaceCanvas(
                            text: $essay,
                            metrics: metrics,
                            goalProgress: goalProgress,
                            saveStatus: saveStatus,
                            isFocusMode: isFocusMode,
                            starterActions: WritingStarterAction.primary,
                            openStarterAction: openStarterAction
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !isFocusMode {
                        WritingAssistantOverlay(
                            selectedTool: $selectedTool,
                            evaluationResponse: evaluationResponse,
                            isEvaluating: isEvaluating,
                            evaluationError: evaluationError,
                            evaluate: evaluateDraft
                        )
                        .frame(width: selectedTool == nil ? 86 : min(430, max(408, proxy.size.width * 0.28)))
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.leading, isFocusMode ? 48 : 34)
                .padding(.trailing, isFocusMode ? 48 : 24)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: essay) { _, _ in
            scheduleAutosave()
        }
        .animation(.easeOut(duration: 0.22), value: isFocusMode)
        .accessibilityIdentifier("writing.root")
    }

    private func clearDraft() {
        essay = ""
        prompt = ""
        evaluationResponse = nil
        evaluationError = nil
        saveStatus = .saved
    }

    private func evaluateDraft() {
        guard !essay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            selectedTool = .evaluation
            evaluationError = "先写一点内容，再提交 AI 评价。"
            return
        }

        selectedTool = .evaluation
        evaluationError = nil
        isEvaluating = true

        Task {
            do {
                let response = try await writingService.evaluate(
                    WritingEvaluateRequest(
                        essay: essay,
                        mode: mode,
                        taskPrompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : prompt
                    )
                )

                await MainActor.run {
                    evaluationResponse = response
                    isEvaluating = false
                }
            } catch {
                await MainActor.run {
                    evaluationError = "评价失败，请稍后重试。"
                    isEvaluating = false
                }
            }
        }
    }

    private func openStarterAction(_ action: WritingStarterAction) {
        if let rawValue = action.toolRawValue,
           let tool = WritingAssistantTool(rawValue: rawValue) {
            selectedTool = tool
        }

        if action.id == "prompt" {
            mode = .exam
        }
    }

    private func scheduleAutosave() {
        saveStatus = .dirty
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                saveStatus = .saving
            }

            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                saveStatus = .saved
            }
        }
    }
}

private struct WritingTopBar: View {
    @Binding var mode: WritingMode
    let metrics: WritingDocumentMetrics
    let goalProgress: WritingGoalProgress
    let saveStatus: WritingSaveStatus
    let isFocusMode: Bool
    let clear: () -> Void
    let submit: () -> Void
    let toggleFocus: () -> Void
    let back: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("返回")

            Spacer()

            Picker("写作模式", selection: $mode) {
                ForEach(WritingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .accessibilityIdentifier("writing.mode")

            Spacer()

            Text(metrics.displayText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .trailing)

            WritingGoalChip(progress: goalProgress)

            Label(saveStatus.displayText, systemImage: saveStatus == .saved ? "checkmark.circle.fill" : "circle.dotted")
                .font(.caption.weight(.semibold))
                .foregroundStyle(saveStatus == .saved ? Color(red: 0.15, green: 0.53, blue: 0.50) : .secondary)
                .frame(minWidth: 86, alignment: .leading)
                .accessibilityIdentifier("writing.saveStatus")

            Button("清空", action: clear)
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityIdentifier("writing.clear")

            Button("提交", action: submit)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color(red: 0.45, green: 0.67, blue: 0.59))
                .accessibilityIdentifier("writing.submit")

            Button(action: toggleFocus) {
                Image(systemName: isFocusMode ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .font(.headline.weight(.semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .accessibilityLabel(isFocusMode ? "退出专注模式" : "进入专注模式")
            .accessibilityIdentifier("writing.focusMode")

            Menu {
                Button("保存草稿", systemImage: "tray.and.arrow.down") {}
                Button("导出文本", systemImage: "square.and.arrow.up") {}
                Button("写作设置", systemImage: "gearshape") {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多")
        }
    }
}

private struct WritingGoalChip: View {
    let progress: WritingGoalProgress

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ProgressView(value: progress.ratio)
                .progressViewStyle(.linear)
                .tint(progress.isComplete ? Color(red: 0.15, green: 0.53, blue: 0.50) : Color.peaiAccent)
                .frame(width: 74)

            Text(progress.displayText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .accessibilityIdentifier("writing.goalProgress")
    }
}

private struct WritingWorkspaceCanvas: View {
    @Binding var text: String
    let metrics: WritingDocumentMetrics
    let goalProgress: WritingGoalProgress
    let saveStatus: WritingSaveStatus
    let isFocusMode: Bool
    let starterActions: [WritingStarterAction]
    let openStarterAction: (WritingStarterAction) -> Void

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("写作工作台")
                        .font(.headline.weight(.semibold))

                    Text(isEmpty ? "先选择一个学习资产入口，或直接开始写。" : "保持写作流，右侧工具按需打开。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isFocusMode {
                    Text("学习资产")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.90, green: 0.97, blue: 0.95), in: Capsule())
                }
            }
            .padding(.horizontal, isFocusMode ? Spacing.lg : Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, isEmpty && !isFocusMode ? Spacing.md : Spacing.sm)

            if isEmpty && !isFocusMode {
                WritingEmptyStarterSection(
                    actions: starterActions,
                    openAction: openStarterAction
                )
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.md)
            }

            ZStack(alignment: .topLeading) {
                WritingEditorView(
                    text: $text,
                    placeholder: isEmpty ? "也可以直接在这里写下第一句英文..." : "继续写作..."
                )
                .padding(.horizontal, isFocusMode ? 34 : Spacing.xl)
                .padding(.top, isEmpty ? Spacing.md : Spacing.lg)
                .padding(.bottom, Spacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))

            HStack(spacing: Spacing.sm) {
                Label(saveStatus.displayText, systemImage: saveStatus == .saved ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundStyle(saveStatus == .saved ? Color(red: 0.15, green: 0.53, blue: 0.50) : .secondary)

                Text("·")
                    .foregroundStyle(.tertiary)

                Text(metrics.displayText)

                Text("·")
                    .foregroundStyle(.tertiary)

                Text("目标 \(goalProgress.displayText)")

                Spacer()

                if isFocusMode {
                    Text("专注模式")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.90, green: 0.97, blue: 0.95), in: Capsule())
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, isFocusMode ? 30 : Spacing.lg)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: isFocusMode ? 18 : 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: isFocusMode ? 18 : 22, style: .continuous)
                .stroke(Color(.separator).opacity(isFocusMode ? 0.18 : 0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isFocusMode ? 0.05 : 0.08), radius: isFocusMode ? 12 : 18, x: 0, y: isFocusMode ? 6 : 10)
    }
}

private struct WritingEmptyStarterSection: View {
    let actions: [WritingStarterAction]
    let openAction: (WritingStarterAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("从学习资产开始")
                    .font(.title3.weight(.bold))

                Spacer()

                Text("模板、素材、题目和草稿会逐步接入后端")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ],
                spacing: Spacing.md
            ) {
                ForEach(actions) { action in
                    WritingStarterCard(action: action) {
                        openAction(action)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier("writing.starterSection")
    }
}

private struct WritingStarterCard: View {
    let action: WritingStarterAction
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: action.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))
                    .frame(width: 34, height: 34)
                    .background(Color(red: 0.90, green: 0.97, blue: 0.95), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(action.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .padding(Spacing.md)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("writing.starter.\(action.id)")
    }
}

private struct WritingPromptBar: View {
    @Binding var prompt: String

    var body: some View {
        TextField("输入考试题目、写作要求或评分标准", text: $prompt, axis: .vertical)
            .font(.body)
            .lineLimit(1...3)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.24), lineWidth: 1)
            }
            .accessibilityIdentifier("writing.prompt")
    }
}

private struct WritingAssistantOverlay: View {
    @Binding var selectedTool: WritingAssistantTool?
    let evaluationResponse: WritingEvaluateResponse?
    let isEvaluating: Bool
    let evaluationError: String?
    let evaluate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            if let selectedTool {
                WritingToolPanel(
                    tool: selectedTool,
                    evaluationResponse: evaluationResponse,
                    isEvaluating: isEvaluating,
                    evaluationError: evaluationError,
                    evaluate: evaluate,
                    close: { self.selectedTool = nil }
                )
                .frame(width: 316)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            WritingToolDock(selectedTool: $selectedTool)
        }
        .animation(.easeOut(duration: 0.22), value: selectedTool)
    }
}

private struct WritingToolDock: View {
    @Binding var selectedTool: WritingAssistantTool?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(WritingAssistantTool.allCases) { tool in
                Button {
                    selectedTool = selectedTool == tool ? nil : tool
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tool.systemImage)
                            .font(.headline.weight(.semibold))
                            .frame(width: 30, height: 24)

                        Text(tool.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(width: 58, height: 54)
                    .foregroundStyle(selectedTool == tool ? .white : Color(red: 0.15, green: 0.47, blue: 0.45))
                    .background(
                        selectedTool == tool ? Color(red: 0.15, green: 0.53, blue: 0.50) : Color(red: 0.90, green: 0.97, blue: 0.95),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tool.title)
                .accessibilityIdentifier("writing.tool.\(tool.rawValue)")
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 12)
    }
}

private struct WritingToolPanel: View {
    let tool: WritingAssistantTool
    let evaluationResponse: WritingEvaluateResponse?
    let isEvaluating: Bool
    let evaluationError: String?
    let evaluate: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(tool.title, systemImage: tool.systemImage)
                        .font(.title3.weight(.bold))

                    Text(tool.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("关闭工具面板")
            }

            if tool == .evaluation {
                WritingResultView(
                    response: evaluationResponse,
                    isEvaluating: isEvaluating,
                    errorMessage: evaluationError,
                    evaluate: evaluate
                )
            } else {
                WritingToolPlaceholder(tool: tool)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(.separator).opacity(0.20), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 26, x: 0, y: 16)
        .accessibilityIdentifier("writing.toolPanel.\(tool.rawValue)")
    }
}

private struct WritingToolPlaceholder: View {
    let tool: WritingAssistantTool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(tool.suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            Button {
            } label: {
                Label(tool.actionTitle, systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.15, green: 0.53, blue: 0.50))
            .padding(.top, Spacing.sm)
        }
    }
}

private enum WritingAssistantTool: String, CaseIterable, Identifiable {
    case evaluation
    case grammar
    case polish
    case sample
    case template
    case material
    case translate
    case coach
    case archive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .evaluation: "评价"
        case .grammar: "语法"
        case .polish: "润色"
        case .sample: "范文"
        case .template: "模板"
        case .material: "素材"
        case .translate: "翻译"
        case .coach: "教练"
        case .archive: "归档"
        }
    }

    var subtitle: String {
        switch self {
        case .evaluation: "评分、结构、表达和语法反馈"
        case .grammar: "定位时态、冠词、从句和搭配错误"
        case .polish: "把普通表达升级成自然英文"
        case .sample: "按当前题目生成可参考范文"
        case .template: "选择考试、邮件、叙事等写作框架"
        case .material: "积累主题词汇、观点和例句"
        case .translate: "中英互译并保留写作语气"
        case .coach: "一步一步陪你搭框架和扩写"
        case .archive: "保存草稿、版本和反馈记录"
        }
    }

    var systemImage: String {
        switch self {
        case .evaluation: "sparkles"
        case .grammar: "checklist.checked"
        case .polish: "wand.and.stars"
        case .sample: "doc.text.magnifyingglass"
        case .template: "square.grid.2x2"
        case .material: "lightbulb"
        case .translate: "character.book.closed"
        case .coach: "person.wave.2"
        case .archive: "tray.and.arrow.down"
        }
    }

    var suggestions: [String] {
        switch self {
        case .evaluation:
            []
        case .grammar:
            ["检查句子主谓一致、时态和冠词。", "把错误按严重程度整理，方便逐条修改。", "保留原句和推荐改法，避免误改含义。"]
        case .polish:
            ["将重复词替换成更自然表达。", "提升连接词和句式变化。", "保留你的原意，不改成模板化英语。"]
        case .sample:
            ["根据当前题目生成高分范文。", "支持按词数、考试类型和难度调整。", "对照你的草稿指出可借鉴结构。"]
        case .template:
            ["自由写作、雅思、托福、邮件都可用。", "提供开头、主体、结尾的可填空框架。", "后续可保存你常用的个人模板。"]
        case .material:
            ["按主题整理观点、例句和词汇。", "支持把好句加入个人素材库。", "后续可和复习计划打通。"]
        case .translate:
            ["先直译，再给自然英文表达。", "保留正式、口语、学术等语气。", "适合从中文想法快速起草英文。"]
        case .coach:
            ["先帮你确定观点，再逐段扩写。", "通过提问引导你完成作文。", "适合不知道怎么开头的时候使用。"]
        case .archive:
            ["保存草稿和每次 AI 反馈版本。", "按题目、考试类型、时间归档。", "后续可回看进步轨迹。"]
        }
    }

    var actionTitle: String {
        switch self {
        case .evaluation: "开始评价"
        case .grammar: "检查语法"
        case .polish: "开始润色"
        case .sample: "生成范文"
        case .template: "选择模板"
        case .material: "整理素材"
        case .translate: "开始翻译"
        case .coach: "开始辅导"
        case .archive: "保存归档"
        }
    }
}

struct WritingRootView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WritingRootView(draftID: WritingHistoryItem.samples[0].id)
        }
    }
}
