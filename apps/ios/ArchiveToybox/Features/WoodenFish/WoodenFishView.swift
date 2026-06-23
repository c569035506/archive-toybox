import SwiftUI

struct WoodenFishView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = WoodenFishViewModel()

    private let meritGold = Color(red: 0.94, green: 0.82, blue: 0.38)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsRow
                theater
                controls
            }
            .padding(24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("电子木鱼")
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.onAppear()
            reconcileFromProfile()
            viewModel.onKnockPerformed = {
                Task { await syncKnock() }
            }
        }
        .onChange(of: appState.profile?.todayMerit) { _, _ in
            reconcileFromProfile()
        }
        .onChange(of: appState.profile?.totalMerit) { _, _ in
            reconcileFromProfile()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBlock(title: "今日功德", value: "\(viewModel.todayMerit)")
            divider
            statBlock(title: "累计功德", value: "\(viewModel.totalMerit)", muted: true)
            divider
            statBlock(
                title: "连击",
                value: "×\(viewModel.combo)",
                highlighted: viewModel.combo > 1
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

    private func statBlock(title: String, value: String, muted: Bool = false, highlighted: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(highlighted ? meritGold : (muted ? .secondary : meritGold.opacity(0.92)))
        }
        .frame(maxWidth: .infinity)
    }

    private var theater: some View {
        ZStack {
            Button(action: {}) {
                WoodenFishSceneView(phase: viewModel.knockPhase)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(
                WoodenFishPressStyle(
                    onPress: { viewModel.knockManualDown() },
                    onRelease: { viewModel.knockManualUp() }
                )
            )
            .disabled(viewModel.mode == .auto)
            .accessibilityIdentifier("woodenFishButton")
            .accessibilityLabel(viewModel.mode == .auto ? "自动敲击中" : "敲木鱼")

            ForEach(viewModel.floats) { item in
                MeritFloatBubbleView(item: item, gold: meritGold)
            }
            .allowsHitTesting(false)
        }
        .frame(minHeight: 300)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Button {
                viewModel.toggleMode()
            } label: {
                HStack(spacing: 14) {
                    Text(viewModel.mode == .manual ? "◎" : "◉")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.mode == .manual ? "开启自动敲" : "切换为手动敲")
                            .font(.headline)
                        Text(
                            viewModel.mode == .manual
                                ? "点击木鱼区域，每次功德 +1"
                                : "按节奏自动敲击，越快连击越高"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("woodenFishModeToggle")

            if viewModel.mode == .auto {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("自动敲速度", systemImage: "speedometer")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(WoodFishSettings.formatAutoIntervalLabel(viewModel.autoIntervalMs))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(meritGold.opacity(0.18), in: Capsule())
                            .foregroundStyle(meritGold)
                    }

                    HStack(spacing: 8) {
                        ForEach(WoodFishRhythm.autoIntervalPresets, id: \.intervalMs) { preset in
                            Button {
                                viewModel.setAutoKnockInterval(preset.intervalMs)
                            } label: {
                                Text(preset.label)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.autoIntervalMs == preset.intervalMs
                                            ? meritGold.opacity(0.22)
                                            : Color.white.opacity(0.06),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundStyle(
                                        viewModel.autoIntervalMs == preset.intervalMs ? meritGold : .secondary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .accessibilityIdentifier("woodenFishSpeedSlider")

                    HStack {
                        Text("快")
                        Spacer()
                        Text("慢")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)))
            }
        }
    }

    private func reconcileFromProfile() {
        let pending = appState.syncQueue.pendingCount(for: .woodenFish)
        let baseToday = appState.profile?.todayMerit ?? 0
        let baseTotal = appState.profile?.totalMerit ?? 0
        if pending > 0 {
            viewModel.applyMerit(today: baseToday + pending, total: baseTotal + pending)
        } else {
            viewModel.applyMerit(today: baseToday, total: baseTotal)
        }
    }

    private func syncKnock() async {
        await appState.recordWoodenFishTap()
        reconcileFromProfile()
    }
}

private struct WoodenFishPressStyle: ButtonStyle {
    let onPress: () -> Void
    let onRelease: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    onPress()
                } else {
                    onRelease()
                }
            }
    }
}

private struct MeritFloatBubbleView: View {
    let item: MeritFloatItem
    let gold: Color
    @State private var risen = false

    var body: some View {
        Text("功德 +\(item.merit)")
            .font(.title3.bold())
            .foregroundStyle(gold)
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            .offset(
                x: item.offsetX,
                y: item.offsetY + (risen ? -item.risePx : 12)
            )
            .opacity(risen ? 0 : 1)
            .scaleEffect(risen ? 1.06 : 0.92)
            .onAppear {
                risen = false
                withAnimation(.easeOut(duration: 1.15)) {
                    risen = true
                }
            }
    }
}
