import SwiftUI

struct MeditationPlayerView: View {
    @EnvironmentObject private var appState: AppState
    let track: MeditationTrack
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DabeiPlayerViewModel()
    @State private var sessionId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                statsRow
                DabeiStageView(
                    playing: viewModel.playing,
                    listenTimeLabel: viewModel.listenTimeLabel,
                    floats: viewModel.floats,
                    onTogglePlay: {
                        Feedback.tap()
                        viewModel.togglePlay()
                    }
                )
                danmakuToggle
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("静心清耳")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("结束") {
                    Task { await finish() }
                }
                .disabled(!viewModel.sessionActive)
                .accessibilityIdentifier("meditationFinishButton")
            }
        }
        .task {
            viewModel.prepare(track: track)
            viewModel.onProgress = { elapsed in
                guard let sessionId else { return }
                Task {
                    try? await appState.api.updateMeditationProgress(sessionId: sessionId, durationSec: elapsed)
                }
            }
            sessionId = try? await appState.api.createMeditationSession(trackId: track.id)
            viewModel.play()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(track.categoryLabel)
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.79, green: 0.57, blue: 0.18))
            Text(track.title)
                .font(.title2.bold())
            Text("播放一段静心音乐，看情绪慢慢飘走。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBlock(
                title: "收听",
                value: viewModel.listenTimeLabel,
                highlighted: viewModel.playing
            )
            divider
            statBlock(
                title: "福运",
                value: "\(viewModel.blessCount)",
                warm: true
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)))
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 1, height: 44)
    }

    private func statBlock(title: String, value: String, warm: Bool = false, highlighted: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(
                    warm
                        ? Color(red: 0.79, green: 0.64, blue: 0.15)
                        : (highlighted ? Color(red: 0.79, green: 0.64, blue: 0.15) : .primary)
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var danmakuToggle: some View {
        Button {
            viewModel.toggleDanmaku()
        } label: {
            HStack {
                Image(systemName: viewModel.danmakuEnabled ? "text.bubble.fill" : "text.bubble")
                Text(viewModel.danmakuEnabled ? "弹幕已开启" : "弹幕已关闭")
                    .font(.subheadline.bold())
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("meditationDanmakuToggle")
    }

    private func finish() async {
        Feedback.success()
        let result = viewModel.finish()
        if let sessionId {
            try? await appState.api.finishMeditationSession(
                sessionId: sessionId,
                durationSec: result.durationSec,
                moodDelta: result.moodDelta
            )
        }
        await appState.refreshProfile()
        await appState.refreshToyboxHome()
        dismiss()
    }
}
