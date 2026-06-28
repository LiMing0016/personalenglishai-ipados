import CoreGraphics
import Foundation

enum ChatComposerLayout {
    static let compactEditorHeight: CGFloat = 46
    static let expandedEditorHeight: CGFloat = 96

    static func isActive(text: String, attachmentCount: Int, isFocused: Bool) -> Bool {
        isFocused ||
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            attachmentCount > 0
    }

    static func editorHeight(isActive: Bool) -> CGFloat {
        isActive ? expandedEditorHeight : compactEditorHeight
    }

    static func canSend(text: String, attachmentCount: Int, isVoiceActive: Bool) -> Bool {
        (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachmentCount > 0) &&
            !isVoiceActive
    }
}
