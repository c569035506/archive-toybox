import AVFoundation
import SwiftUI
import UIKit

struct FortuneCatSceneView: View {
    let speed: Double

    @State private var videoReady = false

    var body: some View {
        ZStack {
            glow
            frameContent
        }
        .frame(maxWidth: 320)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("luckyCatButton")
        .accessibilityLabel("招财猫")
    }

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.91, green: 0.71, blue: 0.35).opacity(0.32),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 140
                )
            )
            .frame(width: 260, height: 220)
            .offset(y: -20)
            .scaleEffect(1.05)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: speed)
    }

    private var frameContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.96, green: 0.92, blue: 0.88))
                .shadow(color: Color(red: 0.47, green: 0.28, blue: 0.13).opacity(0.18), radius: 14, y: 8)

            if let still = stillImage, !videoReady {
                Image(uiImage: still)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            FortuneCatVideoView(speed: speed, videoReady: $videoReady)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .opacity(videoReady ? 1 : 0)
        }
        .aspectRatio(819.0 / 1024.0, contentMode: .fit)
    }

    private var stillImage: UIImage? {
        guard let url = Bundle.main.url(forResource: "fortune-cat-1", withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

private struct FortuneCatVideoView: UIViewRepresentable {
    let speed: Double
    @Binding var videoReady: Bool

    func makeUIView(context: Context) -> FortuneCatPlayerUIView {
        let view = FortuneCatPlayerUIView()
        view.onReadyChanged = { ready in
            DispatchQueue.main.async {
                videoReady = ready
            }
        }
        view.setup(videoName: "fortune-cat-loop")
        return view
    }

    func updateUIView(_ uiView: FortuneCatPlayerUIView, context: Context) {
        uiView.setPlaybackRate(speed)
    }

    static func dismantleUIView(_ uiView: FortuneCatPlayerUIView, coordinator: ()) {
        uiView.teardown()
    }
}

private final class FortuneCatPlayerUIView: UIView {
    var onReadyChanged: ((Bool) -> Void)?

    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var statusObservation: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(videoName: String) {
        guard queuePlayer == nil,
              let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return
        }

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player
        player.isMuted = true
        player.actionAtItemEnd = .none

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        playerLayer = layer

        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let ready = player.timeControlStatus == .playing
            self?.onReadyChanged?(ready)
        }

        player.play()
        onReadyChanged?(true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func setPlaybackRate(_ speed: Double) {
        guard let player = queuePlayer else { return }
        player.playImmediately(atRate: Float(speed))
        onReadyChanged?(true)
    }

    func teardown() {
        statusObservation?.invalidate()
        queuePlayer?.pause()
        queuePlayer = nil
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}
