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
    @State private var text = "Write your essay here."

    var body: some View {
        WritingEditorView(text: $text)
    }
}
