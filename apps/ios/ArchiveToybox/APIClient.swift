import Foundation

final class APIClient {
    var baseURL = URL(string: "http://localhost:3000/v1")!
    private var userId = "demo-user"
    private var token = "user:demo-user"

    func configure(userId: String, token: String) {
        self.userId = userId
        self.token = token
    }

    private func request(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> Data {
        var urlRequest = URLRequest(url: baseURL.appending(path: path))
        urlRequest.httpMethod = method
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(userId, forHTTPHeaderField: "X-User-Id")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            urlRequest.httpBody = try JSONEncoder.api.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.server(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        return data
    }

    func fetchProfile() async throws -> UserProfile {
        try JSONDecoder.api.decode(UserProfile.self, from: try await request("me"))
    }

    func fetchToyboxHome() async throws -> [ToyboxCardModel] {
        struct Payload: Decodable { let cards: [ToyboxCardModel] }
        let payload = try JSONDecoder.api.decode(Payload.self, from: try await request("toybox/home"))
        return payload.cards
    }

    func tapWoodenFish(clientRequestId: String) async throws -> MeritTapResponse {
        try JSONDecoder.api.decode(
            MeritTapResponse.self,
            from: try await request("merit/wooden-fish/tap", method: "POST", body: TapPayload(clientRequestId: clientRequestId))
        )
    }

    func tapLuckyCat(clientRequestId: String) async throws -> FortuneTapResponse {
        try JSONDecoder.api.decode(
            FortuneTapResponse.self,
            from: try await request("fortune/lucky-cat/tap", method: "POST", body: TapPayload(clientRequestId: clientRequestId))
        )
    }

    func fetchMeditationTracks() async throws -> [MeditationTrackDTO] {
        struct Payload: Decodable { let tracks: [MeditationTrackDTO] }
        let data = try await request("meditation/tracks")
        return try JSONDecoder.api.decode(Payload.self, from: data).tracks
    }

    func createMeditationSession(trackId: String) async throws -> String {
        struct Payload: Decodable { let sessionId: String; enum CodingKeys: String, CodingKey { case sessionId = "session_id" } }
        struct Body: Encodable { let trackId: String; enum CodingKeys: String, CodingKey { case trackId = "track_id" } }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("meditation/sessions", method: "POST", body: Body(trackId: trackId))).sessionId
    }

    func updateMeditationProgress(sessionId: String, durationSec: Int) async throws {
        struct Body: Encodable { let durationSec: Int; enum CodingKeys: String, CodingKey { case durationSec = "duration_sec" } }
        _ = try await request("meditation/sessions/\(sessionId)/progress", method: "PATCH", body: Body(durationSec: durationSec))
    }

    func finishMeditationSession(sessionId: String, durationSec: Int, moodDelta: [String: Int]) async throws {
        struct Body: Encodable {
            let durationSec: Int
            let moodDelta: [String: Int]
            enum CodingKeys: String, CodingKey {
                case durationSec = "duration_sec"
                case moodDelta = "mood_delta"
            }
        }
        _ = try await request("meditation/sessions/\(sessionId)/finish", method: "POST", body: Body(durationSec: durationSec, moodDelta: moodDelta))
    }

    func listPracticeCharacters() async throws -> [PracticeCharacterDTO] {
        struct Payload: Decodable { let characters: [PracticeCharacterDTO] }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("argument/practice/characters")).characters
    }

    func createPracticeCharacter(_ input: PracticeCharacterInput) async throws -> PracticeCharacterDTO {
        try JSONDecoder.api.decode(PracticeCharacterDTO.self, from: try await request("argument/practice/characters", method: "POST", body: input))
    }

    func createPracticeSession(_ setup: PracticeSetupPayload) async throws -> PracticeSessionCreated {
        try JSONDecoder.api.decode(PracticeSessionCreated.self, from: try await request("argument/practice/sessions", method: "POST", body: setup))
    }

    func createPracticeSession(characterId: String, scenario: PracticeScenarioPayload) async throws -> PracticeSessionCreated {
        struct Body: Encodable {
            let characterId: String
            let relationship: String?
            let whatHappened: String
            let practiceGoal: String
            enum CodingKeys: String, CodingKey {
                case characterId = "character_id"
                case relationship
                case whatHappened = "what_happened"
                case practiceGoal = "practice_goal"
            }
        }
        let relationship = scenario.relationship.trimmingCharacters(in: .whitespacesAndNewlines)
        return try JSONDecoder.api.decode(
            PracticeSessionCreated.self,
            from: try await request(
                "argument/practice/sessions",
                method: "POST",
                body: Body(
                    characterId: characterId,
                    relationship: relationship.isEmpty ? nil : relationship,
                    whatHappened: scenario.whatHappened,
                    practiceGoal: scenario.practiceGoal
                )
            )
        )
    }

    func sendPracticeMessage(sessionId: String, content: String) async throws -> PracticeMessageDTO {
        struct Body: Encodable { let content: String }
        struct Payload: Decodable { let message: PracticeMessageDTO }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("argument/practice/sessions/\(sessionId)/messages", method: "POST", body: Body(content: content))).message
    }

    func finishPractice(sessionId: String) async throws -> PracticeReviewDTO {
        try JSONDecoder.api.decode(PracticeReviewDTO.self, from: try await request("argument/practice/sessions/\(sessionId)/finish", method: "POST", body: EmptyBody()))
    }

    func createAnalysis(_ input: AnalysisInputPayload) async throws -> AnalysisCreatedDTO {
        try JSONDecoder.api.decode(AnalysisCreatedDTO.self, from: try await request("argument/analysis", method: "POST", body: input))
    }

    func listAnalysis() async throws -> [AnalysisListItem] {
        struct Payload: Decodable { let items: [AnalysisListItem] }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("argument/analysis")).items
    }

    func deleteAnalysis(id: String) async throws {
        _ = try await request("argument/analysis/\(id)", method: "DELETE")
    }

    func searchFriends(shortId: String) async throws -> [FriendUser] {
        struct Payload: Decodable { let users: [FriendUser] }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("friends/search?short_id=\(shortId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortId)")).users
    }

    func listFriends() async throws -> [FriendUser] {
        struct Payload: Decodable { let friends: [FriendUser] }
        return try JSONDecoder.api.decode(Payload.self, from: try await request("friends")).friends
    }

    func listFriendRequests() async throws -> FriendRequestsPayload {
        try JSONDecoder.api.decode(FriendRequestsPayload.self, from: try await request("friends/requests"))
    }

    func sendFriendRequest(toUserId: String) async throws {
        struct Body: Encodable { let toUserId: String; enum CodingKeys: String, CodingKey { case toUserId = "to_user_id" } }
        _ = try await request("friends/requests", method: "POST", body: Body(toUserId: toUserId))
    }

    func acceptFriendRequest(id: String) async throws {
        _ = try await request("friends/requests/\(id)/accept", method: "POST", body: EmptyBody())
    }

    func transferMerit(toUserId: String, amount: Int, clientRequestId: String, message: String?) async throws -> MeritTransferResponse {
        struct Body: Encodable {
            let toUserId: String
            let amount: Int
            let clientRequestId: String
            let message: String?
            enum CodingKeys: String, CodingKey {
                case toUserId = "to_user_id"
                case amount
                case clientRequestId = "client_request_id"
                case message
            }
        }
        return try JSONDecoder.api.decode(
            MeritTransferResponse.self,
            from: try await request("merit/transfer", method: "POST", body: Body(toUserId: toUserId, amount: amount, clientRequestId: clientRequestId, message: message))
        )
    }

    func fetchLegal(doc: String) async throws -> LegalDocument {
        try JSONDecoder.api.decode(LegalDocument.self, from: try await request("legal/\(doc)"))
    }

    func recordPrivacyAck(docType: String, version: String) async throws {
        struct Body: Encodable { let docType: String; let version: String; enum CodingKeys: String, CodingKey { case docType = "doc_type"; case version } }
        _ = try await request("compliance/privacy-ack", method: "POST", body: Body(docType: docType, version: version))
    }
}

private struct EmptyBody: Encodable {}
private struct TapPayload: Encodable {
    let clientRequestId: String
    let tappedAt: String
    enum CodingKeys: String, CodingKey { case clientRequestId = "client_request_id"; case tappedAt = "tapped_at" }
    init(clientRequestId: String) {
        self.clientRequestId = clientRequestId
        self.tappedAt = ISO8601DateFormatter().string(from: Date())
    }
}

struct MeritTapResponse: Decodable {
    let todayMerit: Int
    let totalMerit: Int
    let duplicate: Bool
    enum CodingKeys: String, CodingKey {
        case todayMerit = "today_merit"
        case totalMerit = "total_merit"
        case duplicate
    }
}

struct FortuneTapResponse: Decodable {
    let todayFortune: Int
    let duplicate: Bool
    enum CodingKeys: String, CodingKey {
        case todayFortune = "today_fortune"
        case duplicate
    }
}

struct MeritTransferResponse: Decodable {
    let fromBalance: Int
    let toBalance: Int?
    let duplicate: Bool
    enum CodingKeys: String, CodingKey {
        case fromBalance = "from_balance"
        case toBalance = "to_balance"
        case duplicate
    }
}

struct MeditationTrackDTO: Identifiable, Decodable {
    let id: String
    let title: String
    let category: String
    let audioUrl: String
    let durationSec: Int
    enum CodingKeys: String, CodingKey {
        case id, title, category
        case audioUrl = "audio_url"
        case durationSec = "duration_sec"
    }
}

struct PracticeCharacterDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let relationship: String
    let opponentStyle: String
    let identityDesc: String
    let personalityDesc: String
    let voiceGender: OpponentVoiceGender
    let voiceAge: OpponentVoiceAge
    let memorySummary: String
    let sessionCount: Int

    var voiceProfile: OpponentVoiceProfile {
        OpponentVoiceProfile(gender: voiceGender, age: voiceAge)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, relationship
        case opponentStyle = "opponent_style"
        case identityDesc = "identity_desc"
        case personalityDesc = "personality_desc"
        case voiceGender = "voice_gender"
        case voiceAge = "voice_age"
        case memorySummary = "memory_summary"
        case sessionCount = "session_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        relationship = try container.decode(String.self, forKey: .relationship)
        opponentStyle = try container.decode(String.self, forKey: .opponentStyle)
        identityDesc = try container.decodeIfPresent(String.self, forKey: .identityDesc) ?? ""
        personalityDesc = try container.decodeIfPresent(String.self, forKey: .personalityDesc) ?? ""
        if let gender = try container.decodeIfPresent(String.self, forKey: .voiceGender) {
            voiceGender = OpponentVoiceGender(apiValue: gender)
        } else {
            voiceGender = .female
        }
        if let age = try container.decodeIfPresent(String.self, forKey: .voiceAge) {
            voiceAge = OpponentVoiceAge(apiValue: age)
        } else {
            voiceAge = .middle
        }
        memorySummary = try container.decodeIfPresent(String.self, forKey: .memorySummary) ?? ""
        sessionCount = try container.decodeIfPresent(Int.self, forKey: .sessionCount) ?? 0
    }
}

struct PracticeCharacterInput: Encodable {
    let name: String
    let relationship: String
    let opponentStyle: String
    let identityDesc: String
    let personalityDesc: String
    let voiceGender: OpponentVoiceGender
    let voiceAge: OpponentVoiceAge

    enum CodingKeys: String, CodingKey {
        case name, relationship
        case opponentStyle = "opponent_style"
        case identityDesc = "identity_desc"
        case personalityDesc = "personality_desc"
        case voiceGender = "voice_gender"
        case voiceAge = "voice_age"
    }
}

struct PracticeScenarioPayload {
    let relationship: String
    let whatHappened: String
    let practiceGoal: String
}

struct PracticeSetupPayload: Encodable {
    let opponentLabel: String
    let relationship: String
    let whatHappened: String
    let practiceGoal: String
    let opponentStyle: String
    let opponentIdentityDesc: String
    let opponentPersonalityDesc: String
    let opponentVoiceGender: OpponentVoiceGender
    let opponentVoiceAge: OpponentVoiceAge
    enum CodingKeys: String, CodingKey {
        case opponentLabel = "opponent_label"
        case relationship
        case whatHappened = "what_happened"
        case practiceGoal = "practice_goal"
        case opponentStyle = "opponent_style"
        case opponentIdentityDesc = "opponent_identity_desc"
        case opponentPersonalityDesc = "opponent_personality_desc"
        case opponentVoiceGender = "opponent_voice_gender"
        case opponentVoiceAge = "opponent_voice_age"
    }
}

struct PracticeSessionCreated: Decodable {
    let sessionId: String
    let openingMessage: String
    let opponentVoiceGender: OpponentVoiceGender
    let opponentVoiceAge: OpponentVoiceAge

    var voiceProfile: OpponentVoiceProfile {
        OpponentVoiceProfile(gender: opponentVoiceGender, age: opponentVoiceAge)
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case openingMessage = "opening_message"
        case opponentVoiceGender = "opponent_voice_gender"
        case opponentVoiceAge = "opponent_voice_age"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        openingMessage = try container.decode(String.self, forKey: .openingMessage)
        if let gender = try container.decodeIfPresent(String.self, forKey: .opponentVoiceGender) {
            opponentVoiceGender = OpponentVoiceGender(apiValue: gender)
        } else {
            opponentVoiceGender = .female
        }
        if let age = try container.decodeIfPresent(String.self, forKey: .opponentVoiceAge) {
            opponentVoiceAge = OpponentVoiceAge(apiValue: age)
        } else {
            opponentVoiceAge = .middle
        }
    }
}

struct PracticeMessageDTO: Decodable, Identifiable {
    let id: String
    let role: String
    let content: String
    let createdAt: String?
    enum CodingKeys: String, CodingKey {
        case id, role, content
        case createdAt = "created_at"
    }

    init(id: String, role: String, content: String, createdAt: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

struct PracticeReviewDTO: Decodable {
    let scores: PracticeScores
    let title: String
    let summary: String
    let highlights: [String]?
    let suggestions: [String]?
    let bestQuote: String?
    let poster: PracticePosterPayload?
    enum CodingKeys: String, CodingKey {
        case scores, title, summary, highlights, suggestions, poster
        case bestQuote = "best_quote"
    }
}

struct PracticePosterPayload: Decodable {
    let title: String
    let subtitle: String?
    let bestQuote: String?
    let highlights: [String]?
    let suggestions: [String]?
    let scores: PracticeScores?
    enum CodingKeys: String, CodingKey {
        case title, subtitle, scores, highlights, suggestions
        case bestQuote = "best_quote"
    }
}

struct PracticeScores: Decodable {
    let emotionalStability: Double
    let boundaryExpression: Double
    let logicClarity: Double
    let antiFrameControl: Double
    let relationshipPreservation: Double
    let effectiveResponse: Double
    enum CodingKeys: String, CodingKey {
        case emotionalStability = "emotional_stability"
        case boundaryExpression = "boundary_expression"
        case logicClarity = "logic_clarity"
        case antiFrameControl = "anti_frame_control"
        case relationshipPreservation = "relationship_preservation"
        case effectiveResponse = "effective_response"
    }
    var asArgumentScores: [ArgumentScore] {
        [
            .init(id: "emotion", label: "情绪稳定力", value: emotionalStability),
            .init(id: "boundary", label: "边界表达力", value: boundaryExpression),
            .init(id: "logic", label: "逻辑清晰度", value: logicClarity),
            .init(id: "anti", label: "反带节奏力", value: antiFrameControl),
            .init(id: "relation", label: "关系保留度", value: relationshipPreservation),
            .init(id: "response", label: "有效回应力", value: effectiveResponse),
        ]
    }
}

struct AnalysisInputPayload: Encodable {
    let chatText: String
    let selfSide: String
    let relationship: String
    let analysisGoal: String
    let privacyAcknowledged: Bool
    enum CodingKeys: String, CodingKey {
        case chatText = "chat_text"
        case selfSide = "self_side"
        case relationship
        case analysisGoal = "analysis_goal"
        case privacyAcknowledged = "privacy_acknowledged"
    }
}

struct AnalysisCreatedDTO: Decodable {
    let id: String
    let report: AnalysisReportDTO
}

struct AnalysisReportDTO: Decodable {
    let oneLiner: String
    let rootCause: String
    let escalationPoints: String
    let expressionPatterns: String
    let userStrengths: String
    let userImprovements: String
    let betterPhrasing: String
    let nextReply: String
    let finalAdvice: String
    enum CodingKeys: String, CodingKey {
        case oneLiner = "one_liner"
        case rootCause = "root_cause"
        case escalationPoints = "escalation_points"
        case expressionPatterns = "expression_patterns"
        case userStrengths = "user_strengths"
        case userImprovements = "user_improvements"
        case betterPhrasing = "better_phrasing"
        case nextReply = "next_reply"
        case finalAdvice = "final_advice"
    }
}

struct AnalysisListItem: Identifiable, Decodable {
    let id: String
    let relationship: String
    let analysisGoal: String
    let oneLiner: String
    let createdAt: String?
    enum CodingKeys: String, CodingKey {
        case id, relationship
        case analysisGoal = "analysis_goal"
        case oneLiner = "one_liner"
        case createdAt = "created_at"
    }
}

struct FriendUser: Identifiable, Decodable {
    let id: String
    let shortId: String
    let nickname: String
    let avatarUrl: String?
    let totalMerit: Int?
    enum CodingKeys: String, CodingKey {
        case id, nickname
        case shortId = "short_id"
        case avatarUrl = "avatar_url"
        case totalMerit = "total_merit"
    }
}

struct FriendRequestsPayload: Decodable {
    let incoming: [FriendRequestItem]
    let outgoing: [FriendRequestItem]
}

struct FriendRequestItem: Identifiable, Decodable {
    let id: String
    let fromUser: FriendUser?
    let toUser: FriendUser?
    let createdAt: String?
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_user"
        case toUser = "to_user"
        case createdAt = "created_at"
    }
}

struct LegalDocument: Decodable {
    let version: String
    let title: String
    let content: String
}

enum APIError: LocalizedError {
    case server(String)
    var errorDescription: String? {
        switch self {
        case .server(let message): message
        }
    }
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension JSONEncoder {
    static let api: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}
