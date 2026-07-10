import SwiftUI

struct WritingEditorView: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String = "在这里写下你的作文。") {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            WritingPaperLines()
                .allowsHitTesting(false)

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .lineSpacing(9)
                .foregroundStyle(.primary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .padding(.horizontal, -5)
                .padding(.vertical, -8)
                .accessibilityIdentifier("writing.editor")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WritingPaperLines: View {
    var body: some View {
        GeometryReader { proxy in
            let lineCount = max(8, Int(proxy.size.height / 68))

            VStack(spacing: 67) {
                ForEach(0..<lineCount, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.separator).opacity(0.12))
                        .frame(height: 1)
                }
            }
            .padding(.top, 62)
        }
    }
}

struct WritingEditorView_Previews: PreviewProvider {
    static var previews: some View {
        WritingEditorPreview()
    }
}

private struct WritingEditorPreview: View {
    @State private var text = "在这里写下你的作文。"

    var body: some View {
        WritingEditorView(text: $text)
    }
}
