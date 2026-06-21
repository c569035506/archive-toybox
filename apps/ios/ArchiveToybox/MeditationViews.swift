import SwiftUI

struct MeditationHomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tracks: [MeditationTrack] = []
    @State private var selectedCategory: String?

    private var filtered: [MeditationTrack] {
        guard let selectedCategory else { return tracks }
        return tracks.filter { $0.categoryLabel.contains(selectedCategory) || selectedCategory == "全部" }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("静心弹幕").font(.largeTitle.bold())
                    Text("播放一段静心音乐，看情绪慢慢飘走。").foregroundStyle(.secondary)
                    Text("今日已静心 \(appState.profile?.meditationMinutes ?? 0) 分钟")
                        .font(.caption.bold()).foregroundStyle(.cyan)
                }.listRowBackground(Color.clear)
            }
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "全部", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(["大悲咒", "静心", "白噪音", "自然"], id: \.self) { category in
                            FilterChip(title: category, isSelected: selectedCategory == category) { selectedCategory = category }
                        }
                    }
                }.listRowBackground(Color.clear)
            }
            Section("曲目") {
                ForEach(filtered) { track in
                    NavigationLink { MeditationPlayerView(track: track) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(track.categoryLabel).font(.caption.bold()).foregroundStyle(.cyan)
                            Text(track.title).font(.headline)
                            Text("约 \(max(1, Int(track.duration / 60))) 分钟").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("静心弹幕")
        .task { await loadTracks() }
    }

    private func loadTracks() async {
        if let dtos = try? await appState.api.fetchMeditationTracks() {
            tracks = dtos.map(MeditationTrack.init(dto:))
        } else {
            tracks = fallbackTracks
        }
    }

    private var fallbackTracks: [MeditationTrack] {
        [
            .init(id: "great-compassion-demo", title: "大悲咒静心版", categoryLabel: "大悲咒", resourceName: "great-compassion-demo", duration: 60),
            .init(id: "calm-breathing-demo", title: "三分钟呼吸练习", categoryLabel: "静心音乐", resourceName: "calm-breathing-demo", duration: 90),
            .init(id: "soft-noise-demo", title: "柔和白噪音", categoryLabel: "白噪音", resourceName: "soft-noise-demo", duration: 120),
            .init(id: "rain-window-demo", title: "窗边小雨", categoryLabel: "自然声", resourceName: "rain-window-demo", duration: 120),
        ]
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 9)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.08), in: Capsule())
                .foregroundStyle(isSelected ? Color.black : Color.white)
        }.buttonStyle(.plain)
    }
}

struct MeditationPlayerView: View {
    @EnvironmentObject private var appState: AppState
    let track: MeditationTrack
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundPlayer = SoundPlayer()
    @State private var isPlaying = true
    @State private var elapsed: TimeInterval = 0
    @State private var messages: [BarrageMessage] = []
    @State private var timer: Timer?
    @State private var moodDelta: [String: Int] = [:]
    @State private var sessionId: String?

    private let barragePool: [(String, Bool, String)] = [
        ("快乐 +1", true, "happy"), ("平静 +1", true, "calm"), ("焦虑 -1", false, "anxiety"), ("烦躁 -1", false, "irritation")
    ]

    var body: some View {
        ZStack {
            AppBackground()
            BarrageOverlay(messages: messages)
            VStack(spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("静心弹幕").font(.caption.bold()).foregroundStyle(.cyan)
                    Text(track.title).font(.largeTitle.bold())
                    ProgressView(value: min(1, elapsed / max(track.duration, 1))).tint(.cyan)
                    Text("\(formatTime(elapsed)) / \(formatTime(track.duration))").font(.caption.bold()).foregroundStyle(.secondary)
                }
                .padding(22)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
                Spacer()
                HStack(spacing: 18) {
                    Button("结束") { Task { await finish() } }.buttonStyle(SecondaryButtonStyle())
                    Button { toggle() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title.bold()).frame(width: 76, height: 76)
                            .background(Color.cyan, in: RoundedRectangle(cornerRadius: 28)).foregroundStyle(.black)
                    }.buttonStyle(.plain)
                    Button("再来一条") { spawnBarrage() }.buttonStyle(SecondaryButtonStyle())
                }
            }.padding(22)
        }
        .navigationTitle("播放中")
        .task {
            sessionId = try? await appState.api.createMeditationSession(trackId: track.id)
            soundPlayer.play(resourceName: track.resourceName, loop: true)
            startTimer()
        }
        .onDisappear { timer?.invalidate(); soundPlayer.stop() }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
            if Int(elapsed) % 2 == 0 { spawnBarrage() }
            if let sessionId, Int(elapsed) % 5 == 0 {
                Task { try? await appState.api.updateMeditationProgress(sessionId: sessionId, durationSec: Int(elapsed)) }
            }
        }
    }

    private func toggle() {
        Feedback.tap()
        isPlaying.toggle()
        isPlaying ? soundPlayer.resume() : soundPlayer.pause()
    }

    private func spawnBarrage() {
        guard let item = barragePool.randomElement() else { return }
        moodDelta[item.2, default: 0] += item.1 ? 1 : -1
        messages.append(.init(text: item.0, isPositive: item.1, lane: Int.random(in: 0...7)))
        if messages.count > 18 { messages.removeFirst(messages.count - 18) }
    }

    private func finish() async {
        Feedback.success()
        timer?.invalidate()
        soundPlayer.stop()
        if let sessionId {
            try? await appState.api.finishMeditationSession(sessionId: sessionId, durationSec: Int(elapsed), moodDelta: moodDelta)
        }
        await appState.refreshProfile()
        await appState.refreshToyboxHome()
        dismiss()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

struct BarrageOverlay: View {
    let messages: [BarrageMessage]
    var body: some View {
        GeometryReader { proxy in
            ForEach(messages) { message in
                Text(message.text)
                    .font(.callout.bold())
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(message.isPositive ? Color.cyan.opacity(0.18) : Color.gray.opacity(0.16), in: Capsule())
                    .foregroundStyle(message.isPositive ? Color.green.opacity(0.92) : Color.gray.opacity(0.9))
                    .offset(x: -220)
                    .position(x: proxy.size.width + 180, y: 110 + CGFloat(message.lane) * 54)
            }
        }.allowsHitTesting(false)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.08), in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(.white)
    }
}
