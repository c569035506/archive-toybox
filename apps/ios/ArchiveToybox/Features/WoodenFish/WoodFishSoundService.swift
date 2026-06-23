import AVFoundation

@MainActor
final class WoodFishSoundService {
    static let shared = WoodFishSoundService()

    private var players: [AVAudioPlayer] = []
    private let maxVoices = 6

    private init() {}

    func prepare() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard players.isEmpty else { return }
        guard let url = Bundle.main.url(forResource: "muyu-knock", withExtension: "wav") else {
            return
        }

        for _ in 0..<maxVoices {
            guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = 0.9
            player.prepareToPlay()
            players.append(player)
        }
    }

    func playKnock() {
        if players.isEmpty { prepare() }
        if let idle = players.first(where: { !$0.isPlaying }) {
            idle.currentTime = 0
            idle.play()
            return
        }
        if let fallback = players.first {
            fallback.currentTime = 0
            fallback.play()
        }
    }
}
