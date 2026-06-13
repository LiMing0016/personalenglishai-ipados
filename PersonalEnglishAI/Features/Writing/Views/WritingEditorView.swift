import SwiftUI

struct WritingEditorView: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .padding(Spacing.md)
            .scrollContentBackground(.hidden)
            .background(Color.peaiBackground)
            .accessibilityIdentifier("writing.editor")
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
