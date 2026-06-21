import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var userId: String = KeychainStore.load(key: "userId") ?? "demo-user"
    @Published var authToken: String = KeychainStore.load(key: "authToken") ?? "user:demo-user"
    @Published var hasAcceptedPrivacy: Bool = UserDefaults.standard.bool(forKey: "privacyAccepted")
    @Published var profile: UserProfile?
    @Published var toyboxCards: [ToyboxCardModel] = []
    @Published var lastError: String?

    let api = APIClient()

    func bootstrap() async {
        api.configure(userId: userId, token: authToken)
        await refreshProfile()
        await refreshToyboxHome()
    }

    func refreshProfile() async {
        do {
            profile = try await api.fetchProfile()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshToyboxHome() async {
        do {
            toyboxCards = try await api.fetchToyboxHome()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func acceptPrivacy() {
        hasAcceptedPrivacy = true
        UserDefaults.standard.set(true, forKey: "privacyAccepted")
        Task {
            _ = try? await api.recordPrivacyAck(docType: "privacy", version: "2026-06-21")
        }
    }
}

struct UserProfile: Decodable {
    let id: String
    let shortId: String
    let email: String
    let nickname: String
    let totalMerit: Int
    let todayMerit: Int
    let todayFortune: Int
    let meditationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case shortId
        case email
        case nickname
        case totalMerit = "total_merit"
        case todayMerit = "today_merit"
        case todayFortune = "today_fortune"
        case meditationMinutes = "meditation_minutes"
    }
}

struct ToyboxCardModel: Identifiable, Decodable {
    var id: String { key }
    let key: String
    let title: String
    let description: String
    let actionLabel: String
    let statusText: String
    let totalMerit: Int?

    enum CodingKeys: String, CodingKey {
        case key, title, description
        case actionLabel = "action_label"
        case statusText = "status_text"
        case totalMerit = "total_merit"
    }
}
