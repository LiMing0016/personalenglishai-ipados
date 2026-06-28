import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceInputController: ObservableObject {
    @Published private(set) var state = VoiceInputState()

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasInstalledAudioTap = false
    private var deferredCleanupTask: Task<Void, Never>?

    init(locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "zh-CN")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func start() async {
        guard !state.isRecording && !state.isBusy else {
            return
        }

        guard VoiceInputRuntimeAvailability.supportsLiveRecognition else {
            state.apply(.failed(VoiceInputRuntimeAvailability.unavailableMessage))
            return
        }

        deferredCleanupTask?.cancel()
        deferredCleanupTask = nil
        state.apply(.startRequested)

        let hasPermission = await requestPermissions()
        guard hasPermission else {
            state.apply(.permissionDenied("需要在系统设置中开启麦克风和语音识别权限。"))
            return
        }

        do {
            try startRecognition()
            state.apply(.permissionsGranted)
        } catch {
            cleanupAudioSession(cancelRecognitionTask: true, endAudio: true)
            state.apply(.failed("语音输入暂时不可用，请稍后重试。"))
        }
    }

    func stop() {
        guard state.isRecording || state.isBusy else {
            return
        }

        state.apply(.stopRequested)
        deferredCleanupTask?.cancel()
        deferredCleanupTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self else {
                return
            }

            self.cleanupAudioSession(cancelRecognitionTask: true, endAudio: true)
            self.state.apply(.finished)
            self.deferredCleanupTask = nil
        }
    }

    func resetError() {
        guard state.status == .failed else {
            return
        }

        state.apply(.reset)
    }

    private func requestPermissions() async -> Bool {
        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            return false
        }

        return await requestMicrophonePermission()
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            break
        @unknown default:
            return false
        }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startRecognition() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceInputError.recognizerUnavailable
        }

        cleanupAudioSession(cancelRecognitionTask: true, endAudio: true)

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw VoiceInputError.audioInputUnavailable
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        hasInstalledAudioTap = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else {
                    return
                }

                guard self.state.isActive else {
                    return
                }

                if let result {
                    self.state.apply(.transcriptUpdated(result.bestTranscription.formattedString))
                }

                guard self.state.status != .stopping else {
                    return
                }

                if let error {
                    self.cleanupAudioSession(cancelRecognitionTask: false, endAudio: false)
                    self.state.apply(.failed(error.localizedDescription))
                } else if result?.isFinal == true {
                    self.cleanupAudioSession(cancelRecognitionTask: false, endAudio: false)
                    self.state.apply(.finished)
                }
            }
        }
    }

    private func cleanupAudioSession(cancelRecognitionTask: Bool, endAudio: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledAudioTap = false
        }

        if endAudio {
            recognitionRequest?.endAudio()
        }
        recognitionRequest = nil

        if cancelRecognitionTask {
            recognitionTask?.cancel()
        }
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private enum VoiceInputError: Error {
    case recognizerUnavailable
    case audioInputUnavailable
}
