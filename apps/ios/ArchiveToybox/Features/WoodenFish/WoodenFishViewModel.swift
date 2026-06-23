import Foundation

@MainActor
final class WoodenFishViewModel: ObservableObject {
    @Published var todayMerit = 0
    @Published var totalMerit = 0
    @Published var knockPhase: KnockPhase = .idle
    @Published var floats: [MeritFloatItem] = []
    @Published var combo = 1
    @Published var mode: KnockMode = .manual
    @Published var autoIntervalMs: Int

    private var lastKnockAt: TimeInterval = 0
    private var comboValue = 1
    private var bounceTask: Task<Void, Never>?
    private var autoReleaseTask: Task<Void, Never>?
    private var autoKnockTask: Task<Void, Never>?
    var onKnockPerformed: (() -> Void)?
    private var manualPointerDown = false

    init() {
        autoIntervalMs = WoodFishSettings.loadAutoIntervalMs()
    }

    deinit {
        bounceTask?.cancel()
        autoReleaseTask?.cancel()
        autoKnockTask?.cancel()
    }

    func onAppear() {
        WoodFishSoundService.shared.prepare()
    }

    func onDisappear() {
        stopAutoKnock()
        clearAnimTasks()
    }

    func applyMerit(today: Int, total: Int) {
        todayMerit = today
        totalMerit = total
    }

    func toggleMode() {
        clearAnimTasks()
        manualPointerDown = false
        knockPhase = .idle

        if mode == .manual {
            mode = .auto
            comboValue = 1
            combo = 1
            lastKnockAt = 0
            startAutoKnock(immediate: true)
        } else {
            stopAutoKnock()
            mode = .manual
            comboValue = 1
            combo = 1
            lastKnockAt = 0
        }
    }

    func setAutoKnockInterval(_ ms: Int) {
        let snapped = WoodFishSettings.saveAutoIntervalMs(ms)
        guard snapped != autoIntervalMs else { return }
        autoIntervalMs = snapped
        if mode == .auto {
            startAutoKnock(immediate: false)
        }
    }

    func knockManualDown() {
        guard mode == .manual, !manualPointerDown else { return }
        manualPointerDown = true
        _ = performKnock(source: .manual)
    }

    func knockManualUp() {
        manualPointerDown = false
        guard mode == .manual else { return }
        endKnockAnimation()
    }

    private func startAutoKnock(immediate: Bool = false) {
        stopAutoKnock()
        let intervalMs = autoIntervalMs
        autoKnockTask = Task { [weak self] in
            var nextAt = Date()
            if !immediate {
                nextAt = nextAt.addingTimeInterval(Double(intervalMs) / 1000.0)
            }
            while !Task.isCancelled {
                let delay = max(0, nextAt.timeIntervalSinceNow)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                guard !Task.isCancelled, let self else { return }
                guard self.mode == .auto else { return }
                _ = self.performKnock(source: .auto)
                nextAt = nextAt.addingTimeInterval(Double(intervalMs) / 1000.0)
            }
        }
    }

    private func stopAutoKnock() {
        autoKnockTask?.cancel()
        autoKnockTask = nil
    }

    @discardableResult
    private func performKnock(source: KnockMode) -> Bool {
        let now = Date().timeIntervalSince1970 * 1000
        let gap = now - lastKnockAt
        if source == .manual, gap < Double(WoodFishRhythm.minManualGapMs) {
            return false
        }

        lastKnockAt = now
        WoodFishSoundService.shared.playKnock()
        Feedback.tap()

        var nextCombo = 1
        if source == .auto, gap > 0, gap < Double(WoodFishRhythm.comboWindowMs) {
            nextCombo = min(WoodFishRhythm.maxMeritCombo, comboValue + 1)
        }
        comboValue = nextCombo
        combo = nextCombo

        clearAnimTasks()
        knockPhase = .hit

        if source == .auto {
            autoReleaseTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 70_000_000)
                self?.endKnockAnimation()
            }
        }

        todayMerit += 1
        totalMerit += 1
        spawnFloat(merit: nextCombo)
        onKnockPerformed?()
        return true
    }

    private func endKnockAnimation() {
        clearAnimTasks()
        guard knockPhase == .hit else { return }
        knockPhase = .bounce
        bounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(WoodFishRhythm.bounceMs) * 1_000_000)
            await MainActor.run {
                self?.knockPhase = .idle
            }
        }
    }

    private func spawnFloat(merit: Int) {
        let item = MeritFloatItem(
            merit: merit,
            offsetX: CGFloat.random(in: -100...100),
            offsetY: CGFloat.random(in: -30...50),
            risePx: CGFloat.random(in: 80...130)
        )
        floats.append(item)
        if floats.count > 20 {
            floats.removeFirst(floats.count - 20)
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            await MainActor.run {
                self?.floats.removeAll { $0.id == item.id }
            }
        }
    }

    private func clearAnimTasks() {
        bounceTask?.cancel()
        bounceTask = nil
        autoReleaseTask?.cancel()
        autoReleaseTask = nil
    }
}
