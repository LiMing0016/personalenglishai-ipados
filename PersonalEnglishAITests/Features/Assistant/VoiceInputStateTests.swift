import XCTest
@testable import PersonalEnglishAI

final class VoiceInputStateTests: XCTestCase {
    func testVoiceInputStateMovesFromRequestingPermissionToListening() {
        var state = VoiceInputState()

        state.apply(.startRequested)
        XCTAssertEqual(state.status, .requestingPermission)
        XCTAssertTrue(state.isBusy)

        state.apply(.permissionsGranted)
        XCTAssertEqual(state.status, .listening)
        XCTAssertTrue(state.isRecording)
        XCTAssertNil(state.errorMessage)
    }

    func testVoiceInputStateKeepsRecognizedTextAfterStop() {
        var state = VoiceInputState()

        state.apply(.startRequested)
        state.apply(.permissionsGranted)
        state.apply(.transcriptUpdated("Please help me improve this essay"))
        state.apply(.stopRequested)
        state.apply(.finished)

        XCTAssertEqual(state.status, .idle)
        XCTAssertEqual(state.transcript, "Please help me improve this essay")
        XCTAssertTrue(state.hasTranscript)
    }

    func testVoiceInputStateStopRequestedMovesToStopping() {
        var state = VoiceInputState()

        state.apply(.startRequested)
        state.apply(.permissionsGranted)
        state.apply(.stopRequested)

        XCTAssertEqual(state.status, .stopping)
        XCTAssertFalse(state.isRecording)
        XCTAssertTrue(state.isBusy)
        XCTAssertTrue(state.isActive)
    }

    func testVoiceInputStateStoresPermissionFailure() {
        var state = VoiceInputState()

        state.apply(.startRequested)
        state.apply(.permissionDenied("需要开启麦克风和语音识别权限。"))

        XCTAssertEqual(state.status, .failed)
        XCTAssertEqual(state.errorMessage, "需要开启麦克风和语音识别权限。")
        XCTAssertFalse(state.isRecording)
    }

    func testVoiceInputStateStopsRecordingAfterRecognitionFailure() {
        var state = VoiceInputState()

        state.apply(.startRequested)
        state.apply(.permissionsGranted)
        state.apply(.failed("语音识别暂时不可用。"))

        XCTAssertEqual(state.status, .failed)
        XCTAssertEqual(state.errorMessage, "语音识别暂时不可用。")
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.isActive)
    }

    func testVoiceInputComposerTextMergesTranscriptWithExistingDraft() {
        XCTAssertEqual(
            VoiceInputComposerText.merged(base: "", transcript: "  explain government  "),
            "explain government"
        )
        XCTAssertEqual(
            VoiceInputComposerText.merged(base: "请帮我翻译：", transcript: "I want to improve my speaking."),
            "请帮我翻译：\nI want to improve my speaking."
        )
        XCTAssertEqual(
            VoiceInputComposerText.merged(base: "已有内容", transcript: "   "),
            "已有内容"
        )
    }

    func testVoiceInputRuntimeAvailabilityDocumentsSimulatorFallback() {
        #if targetEnvironment(simulator)
        XCTAssertFalse(VoiceInputRuntimeAvailability.supportsLiveRecognition)
        XCTAssertFalse(VoiceInputRuntimeAvailability.unavailableMessage.isEmpty)
        #else
        XCTAssertTrue(VoiceInputRuntimeAvailability.supportsLiveRecognition)
        #endif
    }

    @MainActor
    func testVoiceInputControllerUsesSimulatorFallbackBeforeStartingAudioPipeline() async {
        #if targetEnvironment(simulator)
        let controller = VoiceInputController()

        await controller.start()

        XCTAssertEqual(controller.state.status, .failed)
        XCTAssertEqual(controller.state.errorMessage, VoiceInputRuntimeAvailability.unavailableMessage)
        XCTAssertFalse(controller.state.isRecording)
        #endif
    }
}
