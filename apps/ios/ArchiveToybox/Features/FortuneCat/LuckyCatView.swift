import SwiftUI

struct LuckyCatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FortuneCatViewModel()

    private let fortuneGold = Color(red: 0.65, green: 0.45, blue: 0.09)
    private let fortuneTextGold = Color(red: 0.79, green: 0.57, blue: 0.18)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                complianceNote
                statsRow
                stage
                speedControl
            }
            .padding(24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("招财猫")
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.onAppear()
            reconcileFromProfile()
            viewModel.onCollectPerformed = {
                Task { await syncCollect() }
            }
        }
        .onChange(of: appState.profile?.todayFortune) { _, _ in
            reconcileFromProfile()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var complianceNote: some View {
        Text("摸摸猫爪，让心情松一点。这里不承诺改变现实，也不涉及改命或发财保证。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBlock(title: "今日财运", value: "\(viewModel.todayFortune)")
            divider
            statBlock(title: "本次招财", value: "\(viewModel.sessionFortune)", warm: true)
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

    private func statBlock(title: String, value: String, warm: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(warm ? fortuneTextGold : .yellow)
        }
        .frame(maxWidth: .infinity)
    }

    private var stage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.92),
                            Color(red: 0.94, green: 0.89, blue: 0.82),
                            Color(red: 0.91, green: 0.83, blue: 0.75),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.71, green: 0.52, blue: 0.29).opacity(0.18))
                )

            FortuneCatSceneView(speed: viewModel.speed)
                .padding(20)
                .zIndex(0)

            ZStack {
                ForEach(viewModel.fortuneFloats) { item in
                    FortuneFloatBubbleView(item: item, color: fortuneGold)
                }
                ForEach(viewModel.coinDrops) { item in
                    CoinDropView(item: item)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
            .allowsHitTesting(false)
        }
        .frame(minHeight: 380)
        .clipped()
    }

    private var speedControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("招财速度")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(FortuneCatSettings.formatSpeedLabel(viewModel.speed)) · \(FortuneCatSettings.formatIntervalLabel(speed: viewModel.speed))")
                    .font(.caption.bold())
                    .foregroundStyle(fortuneTextGold)
            }

            HStack(spacing: 8) {
                ForEach(FortuneCatRhythm.speedPresets, id: \.speed) { preset in
                    Button {
                        viewModel.setSpeed(preset.speed)
                    } label: {
                        Text(preset.label)
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                abs(viewModel.speed - preset.speed) < 0.001
                                    ? fortuneTextGold.opacity(0.18)
                                    : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(
                                abs(viewModel.speed - preset.speed) < 0.001 ? fortuneTextGold : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityIdentifier("luckyCatSpeedSlider")

            HStack {
                Text("慢")
                Spacer()
                Text("快")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)))
    }

    private func reconcileFromProfile() {
        let pending = appState.syncQueue.pendingCount(for: .luckyCat)
        let baseToday = appState.profile?.todayFortune ?? 0
        viewModel.applyTodayFortune(pending > 0 ? baseToday + pending : baseToday)
    }

    private func syncCollect() async {
        await appState.recordLuckyCatTap()
        reconcileFromProfile()
    }
}

private struct FortuneFloatBubbleView: View {
    let item: FortuneFloatItem
    let color: Color
    @State private var risen = false

    var body: some View {
        Text("财运 +1")
            .font(.title3.bold())
            .foregroundStyle(color)
            .shadow(color: .white.opacity(0.9), radius: 2)
            .shadow(color: color.opacity(0.35), radius: 6, y: 2)
            .offset(
                x: item.offsetX,
                y: item.offsetY + (risen ? -item.risePx : 10)
            )
            .opacity(risen ? 0 : 1)
            .scaleEffect(risen ? 1.08 : 0.9)
            .onAppear {
                risen = false
                withAnimation(.easeOut(duration: 1.15)) {
                    risen = true
                }
            }
    }
}

private struct CoinDropView: View {
    let item: FortuneCoinItem
    @State private var dropped = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.81, blue: 0.30),
                            Color(red: 0.78, green: 0.56, blue: 0.14),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1.5))
                .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.05).opacity(0.45), radius: 5, y: 3)

            Text("财")
                .font(.caption2.bold())
                .foregroundStyle(Color(red: 0.45, green: 0.28, blue: 0.04))
        }
        .offset(
            x: item.offsetX,
            y: item.startY + (dropped ? FortuneCatRhythm.coinEndOffsetY : FortuneCatRhythm.coinStartOffsetY)
        )
        .opacity(dropped ? 0 : 1)
        .onAppear {
            dropped = false
            withAnimation(.easeIn(duration: FortuneCatRhythm.coinDropDuration)) {
                dropped = true
            }
        }
    }
}
