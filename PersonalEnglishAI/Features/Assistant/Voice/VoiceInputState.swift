import Foundation

enum VoiceInputStatus: Equatable {
    case idle
    case requestingPermission
    case listening
    case stopping
    case failed
}

enum VoiceInputEvent: Equatable {
    case startRequested
    case permissionsGranted
    case permissionDenied(String)
    case transcriptUpdated(String)
    case stopRequested
    case finished
    case failed(String)
    case reset
}

struct VoiceInputState: Equatable {
    var status: VoiceInputStatus = .idle
    var transcript: String = ""
    var errorMessage: String?

    var isBusy: Bool {
        status == .requestingPermission || status == .stopping
    }

    var isRecording: Bool {
        status == .listening
    }

    var isActive: Bool {
        status == .requestingPermission || status == .listening || status == .stopping
    }

    var hasTranscript: Bool {
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    mutating func apply(_ event: VoiceInputEvent) {
        switch event {
        case .startRequested:
            status = .requestingPermission
            transcript = ""
            errorMessage = nil
        case .permissionsGranted:
            status = .listening
            errorMessage = nil
        case let .permissionDenied(message):
            status = .failed
            errorMessage = message
        case let .transcriptUpdated(value):
            transcript = value
            errorMessage = nil
        case .stopRequested:
            status = .stopping
        case .finished:
            status = .idle
        case let .failed(message):
            status = .failed
            errorMessage = message
        case .reset:
            status = .idle
            transcript = ""
            errorMessage = nil
        }
    }
}

enum VoiceInputComposerText {
    static func merged(base: String, transcript: String) -> String {
        let cleanTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTranscript.isEmpty else {
            return base
        }

        let cleanBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBase.isEmpty else {
            return cleanTranscript
        }

        return "\(cleanBase)\n\(cleanTranscript)"
    }
}

enum VoiceInputRuntimeAvailability {
    static var supportsLiveRecognition: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    static let unavailableMessage = "当前模拟器的本地语音识别不稳定，请在真机上测试语音输入。"
}
