import AVFoundation

@MainActor
final class MeditationSoundService {
    private var player: AVAudioPlayer?

    func prepare(resourceName: String, fileExtension: String = "wav", loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.volume = 0.8
            player?.prepareToPlay()
        } catch {
            print("Meditation audio prepare failed: \(error.localizedDescription)")
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
