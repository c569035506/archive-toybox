import SwiftUI

struct DabeiStageView: View {
    let playing: Bool
    let listenTimeLabel: String
    let floats: [DabeiFloatItem]
    let onTogglePlay: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.17, green: 0.16, blue: 0.14),
                            Color(red: 0.09, green: 0.08, blue: 0.07),
                            Color(red: 0.05, green: 0.04, blue: 0.04),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08))
                )

            ForEach(floats) { item in
                DabeiFloatBubbleView(item: item)
            }

            VStack(spacing: 14) {
                playButton
                Text("\(playing ? "播放中 · " : "已收听 · ")\(listenTimeLabel)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.white.opacity(0.72))
            }
        }
        .frame(minHeight: 360)
        .clipped()
    }

    private var playButton: some View {
        Button(action: onTogglePlay) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(playing ? 0.55 : 0.35), lineWidth: 1)
                        .frame(width: 104, height: 104)
                        .scaleEffect(playing ? 1.12 : 1)
                        .opacity(playing ? 0.35 : 0.85)
                        .animation(playing ? .easeOut(duration: 1.6).repeatForever(autoreverses: false) : .default, value: playing)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: playing
                                    ? [
                                        Color(red: 0.91, green: 0.79, blue: 0.42),
                                        Color(red: 0.66, green: 0.52, blue: 0.13),
                                        Color(red: 0.42, green: 0.32, blue: 0.08),
                                    ]
                                    : [
                                        Color(red: 0.79, green: 0.66, blue: 0.29),
                                        Color(red: 0.55, green: 0.41, blue: 0.08),
                                        Color(red: 0.36, green: 0.27, blue: 0.06),
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 6)

                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(red: 0.10, green: 0.08, blue: 0.03))
                        .offset(x: playing ? 0 : 3)
                }

                Text(playing ? "暂停" : "播放")
                    .font(.subheadline.bold())
                    .tracking(3)
                    .foregroundStyle(Color(red: 0.96, green: 0.90, blue: 0.72))
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("meditationPlayButton")
        .accessibilityLabel(playing ? "暂停" : "播放")
    }
}

private struct DabeiFloatBubbleView: View {
    let item: DabeiFloatItem
    @State private var risen = false

    var body: some View {
        Text(item.label)
            .font(.callout.bold())
            .foregroundStyle(Color(red: 0.94, green: 0.82, blue: 0.38))
            .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
            .offset(
                x: item.offsetX,
                y: (item.offsetY + (risen ? -item.risePx : 10))
            )
            .opacity(risen ? 0 : 1)
            .scaleEffect(risen ? 1.05 : 0.94)
            .onAppear {
                risen = false
                withAnimation(.easeOut(duration: Double(DabeiMantra.floatFadeMs) / 1000.0)) {
                    risen = true
                }
            }
    }
}
