import SwiftUI

struct WritingRootView: View {
    let draftID: String?
    @State private var mode: WritingMode = .free
    @State private var prompt = ""
    @State private var essay = "在这里写下你的作文。"

    var body: some View {
        VStack(spacing: 0) {
            WritingToolbar(mode: $mode, prompt: $prompt)
                .padding(Spacing.md)

            Divider()

            HStack(spacing: 0) {
                WritingEditorView(text: $essay)

                Divider()

                WritingResultView()
                    .frame(width: 320)
            }
        }
        .navigationTitle(draftID == nil ? "新草稿" : "草稿")
        .accessibilityIdentifier("writing.root")
    }
}

private struct WritingToolbar: View {
    @Binding var mode: WritingMode
    @Binding var prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("写作模式", selection: $mode) {
                ForEach(WritingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("writing.mode")

            if mode == .exam {
                TextField("题目要求", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                    .accessibilityIdentifier("writing.prompt")
            }
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
