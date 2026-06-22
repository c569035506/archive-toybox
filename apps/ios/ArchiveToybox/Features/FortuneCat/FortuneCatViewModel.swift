import Foundation

@MainActor
final class FortuneCatViewModel: ObservableObject {
    @Published var speed: Double
    @Published var todayFortune = 0
    @Published var sessionFortune = 0
    @Published var coinDrops: [FortuneCoinItem] = []
    @Published var fortuneFloats: [FortuneFloatItem] = []
    @Published var waving = false

    var onCollectPerformed: (() -> Void)?

    private var autoTask: Task<Void, Never>?
    private var waveTask: Task<Void, Never>?

    init() {
        speed = FortuneCatSettings.loadSpeed()
    }

    deinit {
        autoTask?.cancel()
        waveTask?.cancel()
    }

    var fortuneIntervalMs: Int {
        FortuneCatRhythm.intervalMs(forSpeed: speed)
    }

    func onAppear() {
        FortuneCatSoundService.shared.prepare()
        startAutoCollect(immediate: true)
    }

    func onDisappear() {
        stopAutoCollect()
        waveTask?.cancel()
        waveTask = nil
    }

    func applyTodayFortune(_ value: Int) {
        todayFortune = value
    }

    func setSpeed(_ value: Double) {
        let snapped = FortuneCatSettings.saveSpeed(value)
        guard abs(snapped - speed) > 0.001 else { return }
        speed = snapped
        startAutoCollect(immediate: false)
    }

    private func startAutoCollect(immediate: Bool = false) {
        stopAutoCollect()
        let intervalMs = fortuneIntervalMs
        autoTask = Task { [weak self] in
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
                self.collectFortune()
                nextAt = nextAt.addingTimeInterval(Double(intervalMs) / 1000.0)
            }
        }
    }

    private func stopAutoCollect() {
        autoTask?.cancel()
        autoTask = nil
    }

    func collectFortune() {
        Feedback.tap()
        FortuneCatSoundService.shared.playCoin()

        waveTask?.cancel()
        waving = true
        waveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(FortuneCatRhythm.waveMs) * 1_000_000)
            await MainActor.run {
                self?.waving = false
            }
        }

        todayFortune += 1
        sessionFortune += 1
        spawnFortuneEffects()
        onCollectPerformed?()
    }

    private func spawnFortuneEffects() {
        spawnFortuneFloat()
        spawnCoinDrop()
    }

    private func spawnFortuneFloat() {
        let item = FortuneFloatItem(
            offsetX: CGFloat.random(in: -90...90),
            offsetY: CGFloat.random(in: -50...40),
            risePx: CGFloat.random(in: 72...120)
        )
        fortuneFloats.append(item)
        if fortuneFloats.count > 12 {
            fortuneFloats.removeFirst(fortuneFloats.count - 12)
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(FortuneCatRhythm.floatFadeMs) * 1_000_000)
            await MainActor.run {
                self?.fortuneFloats.removeAll { $0.id == item.id }
            }
        }
    }

    private func spawnCoinDrop() {
        let item = FortuneCoinItem(
            offsetX: CGFloat.random(in: -70...70),
            startY: CGFloat.random(in: -80 ... -20)
        )
        coinDrops.append(item)
        if coinDrops.count > 16 {
            coinDrops.removeFirst(coinDrops.count - 16)
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: FortuneCatRhythm.coinSpawnLifespanNs)
            await MainActor.run {
                self?.coinDrops.removeAll { $0.id == item.id }
            }
        }
    }
}
