import Foundation

@MainActor
final class DabeiPlayerViewModel: ObservableObject {
    @Published var playing = false
    @Published var blessCount = 0
    @Published var listenElapsedSec = 0
    @Published var floats: [DabeiFloatItem] = []
    @Published var danmakuEnabled: Bool

    private let sound = MeditationSoundService()
    private var floatTask: Task<Void, Never>?
    private var listenTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var totalPlayMs: TimeInterval = 0
    private var playSegmentStart: Date?
    private var lastMeritAt: TimeInterval = 0
    private var lastStageFloatAt: TimeInterval = 0
    private var moodDelta: [String: Int] = [:]

    var onProgress: ((Int) -> Void)?

    init() {
        danmakuEnabled = DabeiSettings.loadDanmakuEnabled()
    }

    deinit {
        floatTask?.cancel()
        listenTask?.cancel()
        progressTask?.cancel()
    }

    var listenTimeLabel: String {
        DabeiMantra.formatListenDuration(listenElapsedSec)
    }

    var sessionActive: Bool {
        playing || blessCount > 0 || listenElapsedSec > 0
    }

    func prepare(track: MeditationTrack) {
        sound.prepare(resourceName: track.resourceName, fileExtension: track.fileExtension)
    }

    func onDisappear() {
        pause()
        stopTimers()
    }

    func togglePlay() {
        playing ? pause() : play()
    }

    func play() {
        flushPlaySegment()
        sound.play()
        playing = true
        playSegmentStart = Date()
        startTimers()
        spawnFloat()
    }

    func pause() {
        flushPlaySegment()
        sound.pause()
        playing = false
        playSegmentStart = nil
        listenElapsedSec = Int(totalPlayMs / 1000)
        stopTimers()
    }

    func toggleDanmaku() {
        danmakuEnabled.toggle()
        DabeiSettings.saveDanmakuEnabled(danmakuEnabled)
        if !danmakuEnabled {
            floats.removeAll()
        }
    }

    func finish() -> (durationSec: Int, moodDelta: [String: Int]) {
        pause()
        sound.stop()
        let durationSec = max(1, listenElapsedSec)
        let result = (durationSec, moodDelta)
        resetSession()
        return result
    }

    private func resetSession() {
        blessCount = 0
        listenElapsedSec = 0
        floats.removeAll()
        moodDelta = [:]
        totalPlayMs = 0
        lastMeritAt = 0
        lastStageFloatAt = 0
    }

    private func flushPlaySegment() {
        guard let start = playSegmentStart else { return }
        totalPlayMs += Date().timeIntervalSince(start) * 1000
        playSegmentStart = nil
    }

    private func currentListenMs() -> TimeInterval {
        var ms = totalPlayMs
        if let start = playSegmentStart {
            ms += Date().timeIntervalSince(start) * 1000
        }
        return ms
    }

    private func startTimers() {
        stopTimers()

        listenTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    self.listenElapsedSec = Int(self.currentListenMs() / 1000)
                }
            }
        }

        floatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(DabeiMantra.floatIntervalMs) * 1_000_000)
                await MainActor.run {
                    self?.spawnFloat()
                }
            }
        }

        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    self.onProgress?(self.listenElapsedSec)
                }
            }
        }
    }

    private func stopTimers() {
        floatTask?.cancel()
        floatTask = nil
        listenTask?.cancel()
        listenTask = nil
        progressTask?.cancel()
        progressTask = nil
    }

    private func spawnFloat() {
        let now = Date().timeIntervalSince1970 * 1000
        if now - lastMeritAt >= Double(DabeiMantra.meritIntervalMs) {
            blessCount += 1
            lastMeritAt = now
        }
        guard danmakuEnabled else { return }
        if now - lastStageFloatAt < Double(DabeiMantra.stageFloatIntervalMs) { return }

        let label = DabeiMantra.pickLabel()
        if let parsed = DabeiMantra.moodDelta(for: label) {
            moodDelta[parsed.key, default: 0] += parsed.delta
        }

        let item = DabeiFloatItem(
            label: label,
            offsetX: CGFloat.random(in: -110...110),
            offsetY: CGFloat.random(in: -60...60),
            risePx: CGFloat.random(in: 72...128)
        )
        lastStageFloatAt = now
        floats.append(item)
        if floats.count > DabeiMantra.stageMaxFloats {
            floats.removeFirst(floats.count - DabeiMantra.stageMaxFloats)
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(DabeiMantra.floatFadeMs) * 1_000_000)
            await MainActor.run {
                self?.floats.removeAll { $0.id == item.id }
            }
        }
    }
}
