import XCTest
@testable import PersonalEnglishAI

final class ChatComposerLayoutTests: XCTestCase {
    func testComposerHeightIsCompactByDefaultAndExpandsForActiveInput() {
        XCTAssertEqual(ChatComposerLayout.editorHeight(isActive: false), 46)
        XCTAssertEqual(ChatComposerLayout.editorHeight(isActive: true), 96)
    }

    func testComposerHeightExpandsWhenDraftOrAttachmentsExist() {
        XCTAssertTrue(ChatComposerLayout.isActive(text: "  hello  ", attachmentCount: 0, isFocused: false))
        XCTAssertTrue(ChatComposerLayout.isActive(text: "   ", attachmentCount: 1, isFocused: false))
        XCTAssertFalse(ChatComposerLayout.isActive(text: "   ", attachmentCount: 0, isFocused: false))
    }

    func testComposerCanSendWhenTextOrAttachmentsExistAndVoiceIsInactive() {
        XCTAssertTrue(ChatComposerLayout.canSend(text: " explain window ", attachmentCount: 0, isVoiceActive: false))
        XCTAssertTrue(ChatComposerLayout.canSend(text: "   ", attachmentCount: 1, isVoiceActive: false))
        XCTAssertFalse(ChatComposerLayout.canSend(text: "   ", attachmentCount: 0, isVoiceActive: false))
        XCTAssertFalse(ChatComposerLayout.canSend(text: "hello", attachmentCount: 0, isVoiceActive: true))
    }
}
