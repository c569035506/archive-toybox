import AVFoundation
import Photos
import SwiftUI
import UIKit

@MainActor
final class SoundPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func play(resourceName: String, loop: Bool = false) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "wav") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.volume = 0.75
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
        }
    }

    func pause() { player?.pause() }
    func resume() { player?.play() }
    func stop() { player?.stop(); player = nil }
}

enum Feedback {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

@MainActor
final class PhotoSaver: NSObject, ObservableObject {
    @Published var message: String?

    func save<Content: View>(view: Content, size: CGSize) {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1
        guard let image = renderer.uiImage else {
            message = "海报生成失败"
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            message = "保存失败：\(error.localizedDescription)"
        } else {
            Feedback.success()
            message = "已保存到相册"
        }
    }
}

@MainActor
final class PendingSyncQueue: ObservableObject {
    private var pendingWoodenFish: [String] = []

    func enqueueWoodenFish(clientRequestId: String) {
        pendingWoodenFish.append(clientRequestId)
    }

    func flush(api: APIClient) async {
        for id in pendingWoodenFish {
            _ = try? await api.tapWoodenFish(clientRequestId: id)
        }
        pendingWoodenFish.removeAll()
    }
}
