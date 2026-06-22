import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            ToyboxHomeView()
                .tabItem { Label("玩具盒", systemImage: "shippingbox") }

            FriendsHomeView()
                .tabItem { Label("好友", systemImage: "person.2") }

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }
}

struct ToyboxHomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Archive Toybox").font(.caption.weight(.bold)).foregroundStyle(.cyan)
                        Text("玩具盒").font(.largeTitle.bold())
                        Text("不是游戏，而是一只装满情绪出口的电子玩具盒。")
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .padding(.top, 18)

                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 14) {
                        ForEach(appState.toyboxCards.isEmpty ? fallbackCards : appState.toyboxCards) { card in
                            if let route = route(for: card.key) {
                                NavigationLink(value: route) {
                                    ToyCardView(card: card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppBackground())
            .navigationDestination(for: ToyRoute.self) { route in
                switch route {
                case .woodenFish: WoodenFishView()
                case .luckyCat: LuckyCatView()
                case .argument: ArgumentHomeView()
                case .meditation: MeditationHomeView()
                }
            }
            .refreshable { await appState.refreshToyboxHome() }
        }
    }

    private var fallbackCards: [ToyboxCardModel] {
        [
            .init(key: "wooden_fish", title: "电子木鱼", description: "轻轻敲一下，给今天一点确认感。", actionLabel: "敲一下", statusText: "今日功德 0", totalMerit: 0),
            .init(key: "lucky_cat", title: "招财猫", description: "摸摸猫爪，让心情轻一点。", actionLabel: "摸一下", statusText: "今日招财值 0", totalMerit: nil),
            .init(key: "good_argument", title: "好好吵架", description: "模拟一场对话，或复盘一次真实争吵。", actionLabel: "开始", statusText: "最近复盘：暂无", totalMerit: nil),
            .init(key: "meditation", title: "静心弹幕", description: "播放一段静心音乐，看情绪慢慢飘走。", actionLabel: "开始", statusText: "今日已静心 0 分钟", totalMerit: nil),
        ]
    }

    private func route(for key: String) -> ToyRoute? {
        switch key {
        case "wooden_fish": return .woodenFish
        case "lucky_cat": return .luckyCat
        case "good_argument": return .argument
        case "meditation": return .meditation
        default: return nil
        }
    }
}

struct ToyCardView: View {
    let card: ToyboxCardModel

    private var tint: Color {
        switch card.key {
        case "wooden_fish": return .mint
        case "lucky_cat": return .yellow
        case "good_argument": return .purple
        default: return .cyan
        }
    }

    private var symbol: String {
        switch card.key {
        case "wooden_fish": return "circle.hexagongrid"
        case "lucky_cat": return "pawprint"
        case "good_argument": return "bubble.left.and.bubble.right"
        default: return "sparkles"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 7) {
                Text(card.title).font(.title3.bold())
                Text(card.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                Text(card.statusText).font(.caption.weight(.bold)).foregroundStyle(tint)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.1)))
    }
}

struct WoodenFishView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var soundPlayer = SoundPlayer()
    @State private var scale = 1.0
    @State private var todayMerit = 0
    @State private var totalMerit = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("电子木鱼").font(.largeTitle.bold())
            Text("敲一下，给此刻一点轻轻的确认。").foregroundStyle(.secondary)
            Button {
                todayMerit += 1
                totalMerit += 1
                Feedback.tap()
                soundPlayer.play(resourceName: "wooden-fish")
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { scale = 0.92 }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.08)) { scale = 1 }
                Task {
                    let id = UUID().uuidString
                    if let result = try? await appState.api.tapWoodenFish(clientRequestId: id) {
                        todayMerit = result.todayMerit
                        totalMerit = result.totalMerit
                    }
                    await appState.refreshToyboxHome()
                }
            } label: {
                ZStack {
                    Circle().fill(.brown.gradient).frame(width: 210, height: 210)
                    Image(systemName: "circle.hexagongrid.fill").font(.system(size: 86)).foregroundStyle(.white.opacity(0.88))
                }
                .scaleEffect(scale)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("woodenFishButton")
            Text("今日功德 \(todayMerit) · 总功德 \(totalMerit)").font(.title3.bold()).foregroundStyle(.mint)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("电子木鱼")
        .onAppear {
            todayMerit = appState.profile?.todayMerit ?? 0
            totalMerit = appState.profile?.totalMerit ?? 0
        }
    }
}

struct LuckyCatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var soundPlayer = SoundPlayer()
    @State private var coinBurst = 0
    @State private var todayFortune = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("招财猫").font(.largeTitle.bold())
            Text("摸摸猫爪，让心情松一点。这里不承诺改变现实，也不涉及改命或发财保证。")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button {
                todayFortune += 1
                coinBurst += 1
                Feedback.tap()
                soundPlayer.play(resourceName: "coin")
                Task {
                    if let result = try? await appState.api.tapLuckyCat(clientRequestId: UUID().uuidString) {
                        todayFortune = result.todayFortune
                    }
                    await appState.refreshToyboxHome()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 36).fill(.yellow.opacity(0.18)).frame(width: 230, height: 230)
                    Image(systemName: "cat.fill").font(.system(size: 112)).foregroundStyle(.yellow)
                    Text("+\(coinBurst)").font(.headline.bold()).foregroundStyle(.white).offset(x: 72, y: -78).opacity(coinBurst == 0 ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("luckyCatButton")
            Text("今日招财值 \(todayFortune)").font(.title2.bold()).foregroundStyle(.yellow)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("招财猫")
        .onAppear { todayFortune = appState.profile?.todayFortune ?? 0 }
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.03, green: 0.05, blue: 0.09), Color(red: 0.05, green: 0.08, blue: 0.14)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
