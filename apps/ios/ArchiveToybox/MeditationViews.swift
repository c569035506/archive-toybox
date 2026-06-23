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
            .init(
                id: "great-compassion-demo",
                title: "大悲咒静心版",
                categoryLabel: "大悲咒",
                resourceName: "dabei-mantra",
                fileExtension: "mp3",
                duration: 1722
            ),
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

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.08), in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(.white)
    }
}
