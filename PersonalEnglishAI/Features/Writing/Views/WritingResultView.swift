import SwiftUI

struct WritingResultView: View {
    let response: WritingEvaluateResponse?
    let isEvaluating: Bool
    let errorMessage: String?
    let evaluate: () -> Void

    init(
        response: WritingEvaluateResponse? = nil,
        isEvaluating: Bool = false,
        errorMessage: String? = nil,
        evaluate: @escaping () -> Void = {}
    ) {
        self.response = response
        self.isEvaluating = isEvaluating
        self.errorMessage = errorMessage
        self.evaluate = evaluate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isEvaluating {
                ProgressView("正在生成写作反馈...")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.md)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let response {
                scoreCard(response.score)

                Text(response.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                VStack(spacing: Spacing.sm) {
                    ScoreDimensionRow(title: "任务完成", value: response.score.task)
                    ScoreDimensionRow(title: "逻辑连贯", value: response.score.coherence)
                    ScoreDimensionRow(title: "词汇表达", value: response.score.lexical)
                    ScoreDimensionRow(title: "语法准确", value: response.score.grammar)
                }
            } else if !isEvaluating {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.largeTitle)
                        .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))

                    Text("提交后查看评分与建议")
                        .font(.headline)

                    Text("AI 会从结构、词汇、语法和任务完成度给出反馈。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button(action: evaluate) {
                Label(response == nil ? "开始评价" : "重新评价", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.15, green: 0.53, blue: 0.50))
            .disabled(isEvaluating)
            .accessibilityIdentifier("writing.evaluate")
        }
    }

    private func scoreCard(_ score: WritingScore) -> some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                Text("综合预测")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(score.overall, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.53, blue: 0.50))

                    Text("/ 9")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "seal.fill")
                .font(.title)
                .foregroundStyle(Color(red: 0.45, green: 0.67, blue: 0.59))
        }
        .padding(Spacing.md)
        .background(Color(red: 0.90, green: 0.97, blue: 0.95), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ScoreDimensionRow: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: value, total: 9)
                .tint(Color(red: 0.15, green: 0.53, blue: 0.50))
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct WritingResultView_Previews: PreviewProvider {
    static var previews: some View {
        WritingResultView(
            response: WritingEvaluateResponse(
                requestId: "preview",
                summary: "结构清晰，观点表达明确。可以继续提升连接词和句式变化。",
                score: WritingScore(overall: 7, task: 7, coherence: 6.5, lexical: 7, grammar: 6.5)
            )
        )
        .padding()
    }
}
