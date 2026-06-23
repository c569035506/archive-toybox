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
    @Published private(set) var pendingCount = 0

    private var pending: [PendingTap] = []
    private let storageKey = "pendingTapSyncQueue"

    init() {
        load()
    }

    @discardableResult
    func enqueue(_ kind: PendingTapKind) -> String {
        let item = PendingTap(
            clientRequestId: UUID().uuidString.lowercased(),
            kind: kind,
            tappedAt: Self.isoFormatter.string(from: Date())
        )
        pending.append(item)
        updateCount()
        persist()
        return item.clientRequestId
    }

    func pendingCount(for kind: PendingTapKind) -> Int {
        pending.filter { $0.kind == kind }.count
    }

    func flush(api: APIClient) async {
        guard !pending.isEmpty else { return }

        let batch = pending
        pending = []
        persist()

        var failed: [PendingTap] = []
        for item in batch {
            do {
                switch item.kind {
                case .woodenFish:
                    _ = try await api.tapWoodenFish(clientRequestId: item.clientRequestId)
                case .luckyCat:
                    _ = try await api.tapLuckyCat(clientRequestId: item.clientRequestId)
                }
            } catch {
                failed.append(item)
            }
        }

        pending = failed + pending
        updateCount()
        persist()
    }

    private func updateCount() {
        pendingCount = pending.count
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([PendingTap].self, from: data)
        else {
            pending = []
            updateCount()
            return
        }
        pending = decoded
        updateCount()
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

enum PendingTapKind: String, Codable {
    case woodenFish
    case luckyCat
}

private struct PendingTap: Codable, Equatable {
    let clientRequestId: String
    let kind: PendingTapKind
    let tappedAt: String
}
