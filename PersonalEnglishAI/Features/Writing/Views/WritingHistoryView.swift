import SwiftUI

struct WritingHistoryView: View {
    @Binding var selectedDraftID: String?
    private let drafts = WritingHistoryItem.samples

    var body: some View {
        List {
            ForEach(drafts) { draft in
                Button {
                    selectedDraftID = draft.id
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(draft.title)
                            .font(.headline)
                        Text(draft.preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedDraftID == draft.id ? Color.accentColor.opacity(0.14) : Color.clear)
                .accessibilityIdentifier("writing.draft.\(draft.id)")
            }
        }
        .navigationTitle("写作")
        .toolbar {
            Button {
                selectedDraftID = drafts.first?.id
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("新建草稿")
            .accessibilityIdentifier("writing.newDraft")
        }
        .onAppear {
            selectedDraftID = selectedDraftID ?? drafts.first?.id
        }
    }
}

struct WritingHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        WritingHistoryPreview()
    }
}

private struct WritingHistoryPreview: View {
    @State private var selectedDraftID: String?

    var body: some View {
        NavigationStack {
            WritingHistoryView(selectedDraftID: $selectedDraftID)
        }
    }
}
